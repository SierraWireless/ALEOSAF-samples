-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Sierra Wireless - initial API and implementation
-- 
-- Geofencing sample
-- =================
--
-- Purpose
-- ------- 
-- This sample demonstrates how to develop a complete embedded application
-- controlled through AirVantage servers. It transforms a GPS-enabled asset
-- into a geofencing monitor, i.e. it raises an alarm on the server whenever
-- the device moves out of a predefined area. It also signals when an escaped
-- asset goes back into its fence. It lets the server define the tracking
-- policy (always, never, only when out of fence), redefine the fence, start
-- and stop the application.
--
-- DataStore variables controlling the asset's behavior.
-- -----------------------------------------------------
--
-- The following settings can be controlled from the server:
-- 
--  * `control.started` (Boolean): when false, no reporting is performed. The
--   geofence boundaries are not checked, and the asset position is not reported,
--   even if it breached out of its fence.
--
--  * `control.tracked` (Boolean): when true, the asset continuously reports its
--   position, even if it is inside its fence.
--
--  * `control.trackifescaped` (Boolean): when true, the asset continuously 
--   reports its position, but only it it breached out of its fence.
--
--  * `control.epsilon` (number): allows to reduce the amount of communications by
--    configuring the precision. As long as the asset moves a distance less than `epsilon`
--    in meters, it considers that it didn't move, and that the new position isn't worth
--    being reported. 
--
--  * `command.setfence` (string): describes an area within which the asset must stay.
--    If it locates itself outside of this area, it will consider itself in breach of its
--    fence, report the event to the M2M Operating Portal, and possibly start to report
--    its position continuously, depending on its other settings. The fence description
--    language is detailled below.
--
-- Specifying a geofence area
-- --------------------------
-- The fence specification string format is defined by the `geoloc.area` object.
-- The following options are available:
--
--  * a circle around a point with a given radius:  
--   `"circle <center_latitude>;<center_longitude>;radius_in_meters"`
--
--  * an area delimited by a pair of latitudes, and a pair of longitudes:
--   `"rectangle <latitude_1>;<longitude_1>;<latitude_2>;<longitude_2>"`
--
--  * a polygon delimited by a list of points:
--   `"poly <latitude_1>;<longitude_1>;...;<latitude_n>;<longitude_n>"`
--
--  * The whole surface of the planet: `"everywhere"`
--
--  * the empty surface, to which no point can  belong: `"nowhere"`
--

local sched      = require 'sched'      -- Lua scheduling and synchronization lib
local geoloc     = require 'geoloc'     -- Geolocation lib (points, areas, geometry...)
local airvantage = require 'airvantage' -- ReadyAgent Connector to the m2mop portal
local devicetree = require 'devicetree' -- Access to the device's state variables
local log        = require 'log'        -- Logging library

-- Change logging verbosity. Admissible levels are, by increasing verbosity:
-- `'NONE', 'ERROR', 'WARNING', 'INFO', 'DETAIL', 'DEBUG', 'ALL'`. 
log.setlevel 'INFO'

-- This global variable will contain the asset instance
asset = nil

local GPS_VARS = { 'system.gps.latitude', 'system.gps.longitude' }
local LOG_NAME = 'GEOFENCE'

--------------------------------------------------------------------------------
-- Keep the current state of the application.
-- The information about the application's state are kept either in this table,
-- or in the asset's data tree `asset.tree.control`; the later kind
-- of information can thus be changed remotely from the server as settings,
-- whereas the data in `state` are controlled locally.
--
--  @field last_reported_position the last GPS point reported. Allows to avoid 
--   reporting position moves smaller than asset.tree.control.epsilon (in meters).
--
--  @field fence the current fence area. If you don't want a fence, you can set it to
--   geoloc.newarea 'everywhere': that's the area you can't breach out of.
--
--  @field was_in_fence remembers whether the last position report was in the fence, or
--   out of the fence.  This allows to detect transitions from inside to outside,
--   and vice-versa.
--
--  @table state
state = {
    fence                  = geoloc.newarea 'everywhere';
    last_reported_position = false; 
    was_in_fence           = true;
}

--------------------------------------------------------------------------------
-- Receive the current geolocation, take appropriate reporting measures.
--
-- Detect transition from inside of fence out outside, and vice-versa;
-- report these to the M2M Operating Portal if needed.
-- Also report the current position if approriate (because its set to
-- continuous tracking, and/or because it is escaped and set to report
-- continuously when escaped).
--
-- Relies on the following `state` and ReadyAgent variables:
--
-- * `state.last_reported_position`: last checked position.
-- * `state.was_in_fence`: were we in breach of fence last time we checked?
-- * `asset.tree.control.epsilon`: moves smaller than that are disregarded.
-- * `asset.tree.control.started`: if false, don't report anything.
-- * `asset.tree.control.tracked`: if true, report position at every move.
-- * `asset.tree.control.trackifescaped`: if true, report position whenever the
--    asset is out of its fence.
--
-- @param p the current GPS position, as gathered from aleos variables. If
--   latitude or longitude is missing, they are gathered with a call to
--   `:getvariable()`.
-- @return `"OK"` to indicate successful handling of the callback.
function check_for_fence_breaches(gps_data)
    
    log(LOG_NAME, 'DEBUG', "Checking for fence breaches %s", sprint(gps_data))

    -- Bail out if disabled
    if not asset.tree.control.started then state.last_reported_position=nil; return end

    -- Get GPS position, from parameter if available, from the agent connector if not.
    local lat  = gps_data ['system.gps.latitude']
    local long = gps_data ['system.gps.longitude']
    local p    = geoloc.newpoint(lat, long)

    asset.tree.position.Latitude = lat
    asset.tree.position.Longitude = long

    -- Detect moves across the geofence
    local is_in_fence = state.fence :contains(p)
    if state.was_in_fence and not is_in_fence then
        log(LOG_NAME, 'WARNING', "Reporting a breach out of fence")
        asset :pushdata ("event.breach", tostring(p), "now")
    elseif not state.was_in_fence and is_in_fence then
        log(LOG_NAME, 'INFO', "Reporting a return into the fence")
        asset :pushdata ("event.back", tostring(p), "now")
    end

    -- Report moves, if the asset is tracked and the move is big enough
    -- to be considered relevant (according to Portal var `control.epsilon`).
    local l_pos = state.last_reported_position
    local has_moved = not l_pos or l_pos :distance(p) > asset.tree.control.epsilon
    local must_track = asset.tree.control.tracked or
        (not is_in_fence and asset.tree.control.trackifescaped)
    if has_moved and must_track then
        log(LOG_NAME, 'INFO', "Asset tracked: reporting position")
        asset :pushdata ("position", p, "now")
        state.last_reported_position = p
    end
    
    -- Update the application's state for next iteration
    state.was_in_fence  = is_in_fence
    
    return 'ok'
end

--------------------------------------------------------------------------------
-- React to a `setfence` command received from the M2M Operating Portal.
-- The `setfence` command is sent by the M2M Operating Portal, with a string 
-- description of the area out of which the asset must not go. The string
-- description format is defined in the geoloc library, cf. `geoloc.newarea()`.
-- @param args the Portal command arguments: their must be exactly one, and
--   it must be the string describing the new fence.
-- @return "OK" to indicate successful handling of the callback
function handle_command_setfence (asset, args, path, ticket_id)
    -- Convert the fence description string into an area object,
    -- put it in the application's state.
    local fence_string = args[1]
    local fence, msg = geoloc.newarea (fence_string)
    if not fence then
        log(LOG_NAME, 'ERROR', "Invalid fence specification: %s", msg)
        return nil, msg
    else 
        state.fence = fence
        log(LOG_NAME, 'INFO', "Fence changed to %s", fence_string)
    end

    -- Because the fence has changed, the asset might find itself suddenly
    -- out of fence, or an escaped asset might find itself back in fence. 
    -- Check whether we're in breach of fence.
    check_for_fence_breaches(devicetree.get(GPS_DATA))
    
    return 'ok'
end

--------------------------------------------------------------------------------
-- Main application function.
-- Initialize the ReadyAgent connector, as well as a Telnet shell.
function main()

    log(LOG_NAME, 'INFO', "Application starting")

    assert(airvantage.init())
    assert(devicetree.init())

    -- Initialize the ReadyAgent connector for this asset
    asset = airvantage.newasset 'location'

    -- React to "setfence"  commands from the Portal
    asset.tree.commands.setfence = handle_command_setfence

    -- Portal-controlled state variables
    asset.tree.control = {
        started        = true;  -- Report fence breaches? Yes
        tracked        = false; -- Always position continuously? No
        trackifescaped = true;  -- Report position whenever fence is breached? No 
        epsilon        = 10 }   -- Disregard moves of less than: 10 meters.

    asset.tree.position = { }

    asset :start() -- Start the agent connector

    -- Check the fence every time latitude or longitude change.
    -- By listing variables both as arguments #1 (active) and #3 (passive),
    -- we ensure that both latitude & longitude values are always passed to 
    -- the callback.
    devicetree.register(GPS_VARS, check_for_fence_breaches, GPS_VARS)
    
    log(LOG_NAME, 'INFO', "Application started: waiting for GPS movements and Portal commands.")

end


sched.run(main); sched.loop()
