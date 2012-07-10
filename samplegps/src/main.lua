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

local sched  = require 'sched'
local device = require 'devicetree'
local log    = require 'log'

--
-- These are the actively monitored variables: the monitoring callback will be
-- triggered every time one of these variables change.
--
local GPS_ACTIVE_VARS = {
	'system.gps.latitude',
	'system.gps.longitude',
	'system.gps.fix',
}

--
-- These are the passive variables: the callback won't be triggered simply
-- because one of these changed, but whenever it is triggered because of an
-- active variable, the values of every passive variables will also be passed
-- along as callback parameters.
--
-- The active variables are also listed as passive variables. This way, even if
-- one of them doesn't change, it will still be passed. For instance, even if
-- latitude changes but longitude doesn't (i.e. the device made a pure
-- South/North movement), both latitude and longitude will be passed to the
-- callback.
--
local GPS_PASSIVE_VARS = {
    'system.gps.latitude',
    'system.gps.longitude',
    'system.gps.fix',
	'system.gps.sat_cnt',
	'system.gps.minutes',
	'system.gps.hours',
	'system.gps.day',
	'system.gps.month',
	'system.gps.year',
	'system.gps.seconds'
}


-- a unique log id for the sample
local LOG_NAME = 'GPS'

--------------------------------------------------------------------------------
-- Callback called whenever active GPS values change.
local function gpscallback (gpsvalues)

	-- Display localization and fix date on successful fix
	if gpsvalues['system.gps.fix'] == 1 then
		log (LOG_NAME, "INFO", "Position found: lat=%s;long=%s (number of satellites: %d)", 
            gpsvalues['system.gps.latitude'],
            gpsvalues['system.gps.longitude'],
            gpsvalues['system.gps.sat_cnt'])
		log (LOG_NAME, "INFO", "GPS fix date: 20%d/%d/%d %d:%s:%d (GTM)",
            gpsvalues['system.gps.year'],
            gpsvalues['system.gps.month'],
            gpsvalues['system.gps.day'],
            gpsvalues['system.gps.hours'],
            gpsvalues['system.gps.minutes'],
            gpsvalues['system.gps.seconds'])
	else
		-- No fix available
		log (LOG_NAME, "INFO", "Looking for position (%d satellites detected)",
            gpsvalues['system.gps.sat_cnt'])
	end
end

--------------------------------------------------------------------------------
-- Initialize the devicetree module, starts GPS monitoring.
-- @function [parent=#global] main
--
local function main ()
	log.setlevel("INFO")
	log (LOG_NAME, "INFO", "GPS sample starting...")
	
	-- initialize devicetree before using it
	assert(device.init())
	
	-- add tracking vars to passive vars.
	for _, value in ipairs(GPS_ACTIVE_VARS) do
		table.insert(GPS_PASSIVE_VARS,value)
	end

	-- register the callback for fix, latitude and longitute values change.
	-- the date of the fix, the sattelite count are set as passive variables
	-- because we need to display theses values, but not to be notified of their change.
	-- In our case, it's very useful to avoid to be notified each second by the variable 'system.gps.seconds'
	-- The tracking variables are also set as passive variable, our callback need all theses values.
	-- If we don't add tracking variable to the passive vars, only the var that change will be pass to the callback
	assert(device.register(GPS_ACTIVE_VARS, gpscallback, GPS_PASSIVE_VARS))

end

------------------------------------------------------------------------------
-- Schedule the main function and start the scheduling loop.
sched.run(main)
sched.loop()
