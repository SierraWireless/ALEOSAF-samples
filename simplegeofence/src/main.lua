-- Geofencing Application
-- ======================
--------------------------------------------------------------------------------
local devicetree     = require 'devicetree'      -- Access to the device's state variables
local log            = require 'log'             -- Logging library
local sched          = require 'sched'           -- Lua scheduling and synchronization lib
local simplegeofence = require 'simplegeofence'  -- Geofencing utilities

local function main()
    log('GEOFENCE', 'INFO', "Application starting")
    
    assert(devicetree.init())
    
    -- Register to receive updates to the GPS variables
    -- The callback function will check for fence events and tracking
    devicetree.register(
    	simplegeofence.gps_vars,
    	simplegeofence.check_for_fence_breaches
    )
    
    log('GEOFENCE', 'INFO', "Application started: waiting for GPS movements.")
    
    -- example command to set a fence
    -- change this fence string to define a new fence
    simplegeofence.handle_command_setfence ('circle 37.498193;-121.912836; 100')
end

sched.run(main)
sched.loop()
