---
-- ALEOS AF Device Parameter Access sample.
--
-- @module deviceparameteraccess
--
local devicetree = require 'devicetree'
local sched      = require 'sched'
local os         = require 'os'
local M = {}

--------------------------------------------------------------------------------
-- Variable paths to be used
local LAT         = 'system.gps.latitude'
local LON         = 'system.gps.longitude'
local SAT_CNT     = 'system.gps.sat_cnt'
local SW_VER      = 'system.sw_info.fw_ver'
local DEVICE_NAME = 'system.ddns.service.device_name'
local PWR_IN      = 'system.io.powerin'
local DIN1        = 'system.aleos.io.in1'
local NET_STATE   = 'system.aleos.cellular.state'
local RSSI        = 'system.cellular.link.rssi'

--------------------------------------------------------------------------------
-- Callback function for the GPS variables
local function when_gps_changes (gps_data)
    -- Display every variable name and value passed by Aleos to the callback
    for name, value in pairs(gps_data) do
        print (name, value)
    end
    print ()
end

--------------------------------------------------------------------------------
-- Callback function for the digital input
-- Need to toggle the digital input to see change notifications
local function when_dig_input_changes (din_data)
    print ("Digital input 1 = ", din_data[DIN1])
end

--------------------------------------------------------------------------------
-- One time access of static variables
--
-- @function [parent=#deviceparameteraccess] example_read_variables
function M.example_read_variables ()

    local dname  = devicetree.get (DEVICE_NAME)
    local sw_ver = devicetree.get (SW_VER)
    local powerin = devicetree.get (PWR_IN)
    
    print ("DEVICE name =", dname)
    print ("Software version =", sw_ver)
    print ("powerin = ", powerin, " volts")
    print ()
end

--------------------------------------------------------------------------------
-- Change a variable's value, check that the change took effect.
--
-- @function [parent=#deviceparameteraccess] example_set_variables
function M.example_set_variables ()
    local dname  = devicetree.get (DEVICE_NAME)
    print ("Device name =", dname)
    
    print ("Set a variable - append 'Z' to device name")
    assert (devicetree.set(DEVICE_NAME, dname .. 'Z'))
    new_name = devicetree.get(DEVICE_NAME)
    print ("New Device Name =  ", new_name)
    sched.wait(2)
    
    print ('Set name back to the original...')
    assert (devicetree.set(DEVICE_NAME, dname))
	dname  = devicetree.get (DEVICE_NAME)
    print ("Device name =", dname)
end

--------------------------------------------------------------------------------
-- Be notified, through a callback, every time a given variable changes.
-- This is done through method:
--    devicetree.register (list_of_variables, callback, passive_vars)
--
-- @function [parent=#deviceparameteraccess] example_monitor_variable
-- @return A registration id, to be passed to devicetree.unregister in order to
--  unsubscribe.
-- @return #nil In case of error.
function M.example_monitor_variable ()
    local din_id = assert (devicetree.register(DIN1, when_dig_input_changes))
    return din_id
end

--------------------------------------------------------------------------------
-- Monitor GPS latitude, longitude, and satellite count.
--
-- Every time one of the variables change, the `"when_gps_changes"` callback is
-- called with all the variables of the set that changed.
--
-- @function [parent=#deviceparameteraccess] example_monitor_several_variables
function M.example_monitor_several_variables ()
    -- Subscribe to a set of variables
    print ("Registering GPS variables\n")
    local gps_variables = { LAT, LON, SAT_CNT }
    local gps_id = assert (devicetree.register(gps_variables, when_gps_changes))

    -- Pause to see notifications
    sched.wait(5) 

    -- Unsubscribe from notifications
    print ("unregistering GPS vars...")
    devicetree.unregister (gps_id)
    sched.wait(5) -- Notifications should stop
end

--------------------------------------------------------------------------------
-- Monitor GPS variables plus "passive" variables.
--
-- When one of the GPS variables change, the `"when_gps_changes"` callback is
-- called with each of the variables of the set that changed.
-- Moreover, whenever any GPS variable change triggers the callback,
-- the `"passive"` variables are also included.
-- Since net variables are passed as `"passive"` here,
-- a change in the net variables won't trigger the callback.
--
-- @function [parent=#deviceparameteraccess] example_monitor_passive_variables
function M.example_monitor_passive_variables ()
    print ("Registering GPS variables and passive vars\n")
    local gps_variables = { LAT, LON, SAT_CNT }
    local net_variables = { NET_STATE, RSSI }
    local gps_id = assert (devicetree.register(gps_variables, when_gps_changes, net_variables))

    -- Pause to see notifications
    sched.wait(5) 

    -- Unsubscribe from notifications
    print ("unregistering GPS vars...")
    devicetree.unregister (gps_id)
    sched.wait(5) -- Notifications should stop
end
return M
