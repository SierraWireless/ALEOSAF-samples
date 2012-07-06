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
local LAT         = 'system.gps.latitude'
local LON         = 'system.gps.longitude'
local SAT_CNT     = 'system.gps.sat_cnt'
local SW_VER      = 'system.sw_info.fw_ver'
local DEVICE_NAME = 'system.ddns.service.device_name'
local PWR_IN      = 'system.io.powerin'
local DIN1        = 'system.aleos.io.in1'
local NET_STATE   = 'system.aleos.cellular.state'
local RSSI        = 'system.cellular.link.rssi'
local CELLULAR_SERVICE = 'system.cellular.link.service'
local CELLULAR_NODE = 'system.cellular.link' 
local APN = 'system.cellular.apn.apn'

local logname     = 'PARAM_ACCESS'

--------------------------------------------------------------------------------
-- Callback function for the digital input
-- Need to toggle the digital input to see change notifications
--
local function rssicallback (values)
	log (logname, "INFO" ,"RSSI value change to: %s", values[RSSI])
end

--------------------------------------------------------------------------------
-- Callback function for the GPS variables
--
local function rssiorservicecallback (values)
	-- Display every variable name and value passed by Aleos to the callback
	log (logname, "INFO", "One or both of RSSI and Cellular service variables change")
	for name, value in pairs(values) do
		log (logname, "INFO", "Celluar variable named %s value is %s",name, value)
	end
end


--------------------------------------------------------------------------------
-- Callback function for the GPS variables
--
local function celluarcallback (values)
	-- Display every variable name and value passed by Aleos to the callback
	log (logname, "INFO", "One or several celluar variables change")
	for name, value in pairs(values) do
		log (logname, "INFO", "Celluar variable named %s value is %s",name, value)
	end
end

--------------------------------------------------------------------------------
-- Callback function for the GPS variables
--
local function celluarwithpassivecallback (values)
	-- Display every variable name and value passed by Aleos to the callback
	log (logname, "INFO", "One or several celluar variables change passive")
	for name, value in pairs(values) do
		log (logname, "INFO", "Celluar variable named %s value is %s",name, value)
	end
end

--------------------------------------------------------------------------------
-- Initialize the devicetree module, run all examples, cleanup and exit.
-- @function [parent=#global] main
--
function main ()
	log.setlevel("INFO")
	log(logname, "INFO", "Application starting...")

	-- Intialize device tree before using it
	assert (devicetree.init())

	--
	-- Log some variables
	local dname  = assert(devicetree.get (DEVICE_NAME))
	log(logname, "INFO", "Device name: %s", dname)

	local swver = assert(devicetree.get (SW_VER))
	log(logname, "INFO", "Software version: %s", swver)

	local powerin = assert(devicetree.get (PWR_IN))
	log(logname, "INFO", "Power in: %sV", powerin)

	--
	-- Change a variable's value
	-- Append 'Z' to the APN
	-- WARNING, this code change your APN and may broke your over the air data connection
	local var = devicetree.get('system.aleos.lan')
	local hostname = assert (devicetree.get(APN))
	hostname = hostname .. 'Z'
	assert (devicetree.set(APN, hostname))
	log(logname, "INFO", "Setting APN setting to: %s", hostname)

	--
	-- Be notified, through a callback, every time a given variable changes.
	-- This is done through method:
	--    devicetree.register
	--
	log(logname, "INFO", "Start listening to RSSI variable")
	local rssiid = assert (devicetree.register(RSSI, rssicallback))
	-- Wait 30s and stop listening
	sched.wait(30)
	log(logname, "INFO", "Stop listening to RSSI variable")
	devicetree.unregister (rssiid)

	--
	-- Listen to several variables
	-- Every time one or both of the variables change, the associated callback is called
	log(logname, "INFO", "Start listening to both RSSI and Cellular Service variables")
	local celluarvariables = { RSSI, CELLULAR_SERVICE }
	local celularid = assert (devicetree.register(celluarvariables, rssiorservicecallback))
	-- Wait 30s and stop listening
	sched.wait(30)
	log(logname, "INFO", "Stop listening to RSSI and Cellular Service variables")
	devicetree.unregister (celularid)

	--
	-- Monitor GPS variables plus "passive" variables.
	--
	-- When one of the celluar variables change, the callback is
	-- called with each of the variables of the set that changed.
	-- Moreover, for each call of the callback,
	-- the `"passive"` variables are also included.
	-- Since net variables are passed as `"passive"` here,
	-- a change in the net variables won't trigger the callback.
	log(logname, "INFO", "Start listening to RSSI and Cellular services with passive variables")
	local active_variables = { RSSI, CELLULAR_SERVICE }
	local passive_variables = { DEVICE_NAME, PWR_IN }
	assert (devicetree.register(active_variables, celluarwithpassivecallback, passive_variables))

	-- Don't stop to listen, the remainng registed callbacks are still notified as the sample is running, see sched.loop()
	log(logname, "INFO", "Sample terminated, the last listening callback is still active")
end

-------------------------------------------------------------------------------
-- Schedule the main function
sched.run(main)
-- Launch the main loop, to continue to receive registred notification
sched.loop()
