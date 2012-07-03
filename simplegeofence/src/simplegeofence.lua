-- Geofencing Library
-- ===================.
--
-- Fence definitions:
-- circle_fence_string =      "circle center_latitude; center_longitude; radius_in_meters"
-- rectangular_fence_string = "rectangle latitude_1; longitude_1; latitude_2; longitude_2"
-- polygonal_fence_string =   "poly latitude_1; longitude_1;...; latitude_n; longitude_n"
-- @module simplegeofence

--------------------------------------------------------------------------------
local sched      = require 'sched'      -- Lua scheduling and synchronization lib
local geoloc     = require 'geoloc'     -- Geolocation lib (points, areas, geometry...)
local devicetree = require 'devicetree' -- Access to the device's state variables
local log        = require 'log'        -- Logging library
--------------------------------------------------------------------------------
log.setlevel 'INFO'

local M = {}
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

---
-- Will register to receive updates for these GPS variables.
--
-- @field [parent=#simplegeofence] #table gps_vars
M.gps_vars = {
    'system.gps.latitude',
    'system.gps.longitude',
    'system.gps.fix'
}

---
-- Callback function for GPS changes.
--
-- @function [parent=#simplegeofence] check_for_fence_breaches
-- @param #table gps_data optional
-- @return #string `'ok'`
function M.check_for_fence_breaches (gps_data)
    -- update the GPS fix if changed
    local fix  = gps_data ['system.gps.fix'] or state.fix
    state.fix = fix
    if fix == 0 then return 'ok' end  -- Bail out if no GPS fix
    
    -- Get the new GPS position
    local lat  = gps_data ['system.gps.latitude']  or state.lat
    local long = gps_data ['system.gps.longitude'] or state.long
    state.lat  = lat
    state.long = long
    local p    = geoloc.newpoint(lat, long)
    -- Bail out if disabled
    if not control.started then state.last_reported_position = nil; return 'ok' end
    
    -- Detect moves across the geofence
    local is_in_fence = state.fence:contains(p) -- Check if new point is inside fence
    if state.was_in_fence and not is_in_fence then
        log ('GEOFENCE', 'INFO', 'Reporting exit from fence')
        -- Add desired action here
    elseif not state.was_in_fence and is_in_fence then
        log ('GEOFENCE', 'INFO', 'Reporting entry into fence')
        -- Add desired action here
    end
    -- Update the state
    state.was_in_fence  = is_in_fence
    
    -- Check if tracking is enabled
    if control.always_track or (control.track_outside and not is_in_fence)then
        -- Test if have moved more than the 'delta' distance
        local l_pos = state.last_reported_position
        if not l_pos or l_pos:distance(p) > control.delta then
            state.last_reported_position = p  -- Only update after moving greater than 'delta'
            log ('GEOFENCE', 'DETAIL', 'Tracking: updating position')
            -- Do something like send the updated position
        end
    end
    return 'ok'
end

---
-- The 'setfence' command contains one argument that is a string describing the new fence.
--
-- @function [parent=#simplegeofence] handle_command_setfence
-- @param #string fence_string New fence description
function M.handle_command_setfence (fence_string)
    -- Convert the fence description string into an area object
    print (fence_string)
    local fence, err = geoloc.newarea (fence_string)
    if not fence then
        log ('GEOFENCE', 'ERROR', 'Invalid fence specification: ' .. err)
    else
        state.fence = fence
        log ('GEOFENCE', 'INFO', 'Fence changed to ' .. fence_string)
        -- Because the fence has changed, the vehicle may now be
        -- outside of the fence, or back inside the fence
        -- Check whether the fence state changed
        M.check_for_fence_breaches{}
    end
    return 'ok'
end
return M
