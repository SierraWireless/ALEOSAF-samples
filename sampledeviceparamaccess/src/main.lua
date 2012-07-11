-------------------------------------------------------------------------------
-- Copyright (c) 2012 Sierra Wireless and others.
-- All rights reserved. This program and the accompanying materials
-- are made available under the terms of the Eclipse Public License v1.0
-- which accompanies this distribution, and is available at
-- http://www.eclipse.org/legal/epl-v10.html
--
-- Contributors:
--     Sierra Wireless - initial API and implementation
-------------------------------------------------------------------------------

--
-- ALEOS AF Device Parameter Access sample.
--
local devicetree        = require 'devicetree'
local sched             = require 'sched'
local os                = require 'os'
local log 				= require 'log'

--------------------------------------------------------------------------------
-- Variable paths to be used
local SW_VER      = 'system.sw_info.fw_ver'
local DEVICE_NAME = 'system.ddns.service.device_name'
local PWR_IN      = 'system.io.powerin'
local DIN1        = 'system.aleos.io.in1'
local NET_STATE   = 'system.aleos.cellular.state'
local RSSI        = 'system.cellular.link.rssi'
local CELLULAR_SERVICE = 'system.cellular.link.service'
local CELLULAR_NODE = 'system.cellular.link' 
local APN = 'system.cellular.apn.apn'

local LOG_NAME     = 'PARAM_ACCESS'

--------------------------------------------------------------------------------
-- Callback function which prints every name/value pair passed to it.
-- By registering it through `devicetree.register()`, one gets to view whenever
-- a callback is triggered, and which variables have been passed to it.
--
local function print_callback (values)
    -- Display every variable name and value passed by Aleos to the callback
    log (LOG_NAME, "INFO", "Some variables registered for change monitoring have changed:")
    for name, value in pairs(values) do
        log (LOG_NAME, "INFO", " - Variable %s now has value %s",name, value)
    end
    log (LOG_NAME, "INFO", "   (end of variables list)")
end

--------------------------------------------------------------------------------
-- Initialize the devicetree module, run all examples, cleanup and exit.
-- @function [parent=#global] main
--
function main ()
    log.setlevel("INFO")
    log(LOG_NAME, "INFO", "Application starting...")

    -- Intialize device tree before using it
    assert (devicetree.init())

    --
    -- Log some variables
    local dname  = assert(devicetree.get (DEVICE_NAME))
    log(LOG_NAME, "INFO", "Device name: %s", dname)

    local swver = assert(devicetree.get (SW_VER))
    log(LOG_NAME, "INFO", "Software version: %s", swver)

    local powerin = assert(devicetree.get (PWR_IN))
    log(LOG_NAME, "INFO", "Power in: %sV", powerin)

    --
    -- Change a variable's value
    -- Append 'Z' to the APN
    -- WARNING, this code changes your APN and may break your wireless data connection
    --
    local var = devicetree.get('system.aleos.lan')
    local hostname = assert (devicetree.get(APN))
    hostname = hostname .. 'Z'
    assert (devicetree.set(APN, hostname))
    log(LOG_NAME, "INFO", "Setting APN setting to: %s", hostname)

    --
    -- Be notified, through a callback, every time a given variable changes.
    -- The callback is attached to the variable with `devicetree.register()`.
    --
    log(LOG_NAME, "INFO", "Start listening to RSSI variable")
    local rssiid = assert (devicetree.register(RSSI, print_callback))
    -- Wait 30s and stop listening
    sched.wait(30)
    log(LOG_NAME, "INFO", "Stop listening to RSSI variable")
    devicetree.unregister (rssiid)

    --
    -- Listen to several variables
    -- Every time one or both of the variables change, the associated callback is called
    --
    log(LOG_NAME, "INFO", "Start listening to both RSSI and Cellular Service variables")
    local cellularvariables = { RSSI, CELLULAR_SERVICE }
    local celularid = assert (devicetree.register(cellularvariables, print_callback))
    -- Wait 30s and stop listening
    sched.wait(30)
    log(LOG_NAME, "INFO", "Stop listening to RSSI and Cellular Service variables")
    devicetree.unregister (celularid)

    --
    -- Monitor boath active and passive variables.
    --
    -- The callback is only triggered when one of the active variables changes.
    -- However, whenever triggered, the callback function receives all of the
    -- active variables which actually changed, plus every passive variable,
    -- whether its value changed or not. Notice that a variable can be listed 
    -- as both active and passive, so that it triggers the callback when it
    -- changes, and it's passed to the
    -- callback even if it hadn't changed.
    --
    log(LOG_NAME, "INFO", "Start listening to RSSI and Cellular services with passive variables")
    local active_variables = { RSSI, CELLULAR_SERVICE }
    local passive_variables = { DEVICE_NAME, PWR_IN }
    assert (devicetree.register(active_variables, print_callback, passive_variables))

    -- Don't stop to listen, the remainng registed callbacks are still notified as the sample is running, see sched.loop()
    log(LOG_NAME, "INFO", "Sample execution finished, but the last listening callback is still active")
end

-------------------------------------------------------------------------------
-- Schedule the main function and start the scheduling loop.
sched.run(main)
sched.loop()
