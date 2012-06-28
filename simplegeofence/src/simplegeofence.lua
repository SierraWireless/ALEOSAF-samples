-------------------------------------------------------------------------------
-- # Geofencing Application.
--
-- This document will guide you in creating a geofencing application that will
-- operate in the GPS and Sierra Wireless ALEOS AF enabled modems.
-------------------------------------------------------------------------------
local sched      = require 'sched'      -- Lua scheduling and synchronization library
local geoloc     = require 'geoloc'     -- Geolocation library
local devicetree = require 'devicetree' -- Access to the device's variables
local log        = require 'log'        -- logging library
-------------------------------------------------------------------------------
log.setlevel 'INFO'
 
local state = {
    fence                  = geoloc.newarea 'everywhere';
    last_reported_position = false;
    was_in_fence           = true;
    lat                    = 0;
    long                   = 0;
    fix                    = 0;
}
 
local control = {
        started        = true;  -- Proceed with fence checking and trackng? Yes
        always_track   = false; -- Always track inside and outside of the fence? No
        track_outside  = true;  -- Track only outside the fence? Yes
        delta          = 100    -- Minimum distance to be a change in position: 100 meters.
    }
 
-- Will register to receive updates for these GPS variables
local gps_vars = {
    'system.gps.latitude',
    'system.gps.longitude',
    'system.gps.fix'
}
 
--------------------------------------------------------------------------------
-- callback function for GPS changes
local function check_for_fence_breaches (gps_data)
    -- update the GPS fix if changed
    local fix  = gps_data ['system.gps.fix'] or state.fix
    state.fix = fix
    if fix == 0 then return 'ok' end  -- Bail out if no GPS fix
 
    -- Get the new GPS position
    local lat  = gps_data ['system.gps.latitude']  or state.lat
    local long = gps_data ['system.gps.longitude'] or state.long
 
    -- Update the state
    state.lat  = lat
    state.long = long
 
    local p    = geoloc.newpoint(lat, long)
 
    -- Bail out if disabled
    if not ra.tree.control.started then state.last_reported_position = nil; return 'ok' end
 
    -- Detect moves across the geofence
    local is_in_fence = state.fence:contains(p) -- Check if new point is inside fence
 
    if state.was_in_fence and not is_in_fence then
        log ('GEOFENCE', 'INFO', 'Reporting exit from fence')
        -- Implement desired action here
 
    elseif not state.was_in_fence and is_in_fence then
        log ('GEOFENCE', 'INFO', 'Reporting entry into fence')
        -- Implement desired action here
    end
 
    -- Update the state
    state.was_in_fence  = is_in_fence
 
    -- Check if tracking is enabled
    if ra.tree.control.always_track or (ra.tree.control.track_outside and not is_in_fence)then
        -- Test if have moved more than the 'delta' distance
        local l_pos = state.last_reported_position
 
        if not l_pos or l_pos:distance(p) > ra.tree.control.delta then
            state.last_reported_position = p  -- Only update after moving greater than 'delta'
            log ('GEOFENCE', 'DETAIL', 'Tracking: updating position')
            -- Implement desired action here
        end
    end
 
    return 'ok'
end
 
--------------------------------------------------------------------------------
-- The 'setfence' command is invoked
-- with one argument that is a string describing the new fence
 
function handle_command_setfence (fence_string)
 
    local fence, err_msg = geoloc.newarea (fence_string)
 
    if not fence then
        log ('GEOFENCE', 'ERROR', 'Invalid fence specification: ' .. err_msg)
    else
        state.fence = fence
        log ('GEOFENCE', 'INFO', 'Fence changed to ' .. fence_string)
 
        -- Because the fence has changed, the vehicle may now be
        -- outside of the fence, or back inside the fence
        -- Check whether the fence state changed
        check_for_fence_breaches{}
    end
 
    return 'ok'
end
--------------------------------------------------------------------------------
 
function main()
 
    log('GEOFENCE', 'INFO', "Application starting")
 
    assert(devicetree.init())
 
    -- Register to receive updates to the GPS variables
    -- The callback function will check for fence events and tracking
    devicetree.register (gps_vars, check_for_fence_breaches)
 
    log('GEOFENCE', 'INFO', "Application started: waiting for GPS movements.")
 
    -- example command to set a fence
    -- change this fence string to define a new fence
    handle_command_setfence ('circle 37.498193;-121.912836; 100')
end
 
sched.run(main); sched.loop()