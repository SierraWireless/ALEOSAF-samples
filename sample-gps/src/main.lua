local sched = require 'sched'
local device = require 'devicetree'
local log = require 'log'

-- table of variable we will be notified
local gpsvars = {
	'system.gps.latitude',
	'system.gps.longitude',
	'system.gps.fix',
}
-- table of variable we want to know but not notified 
local gpspassivevars = {
	'system.gps.sat_cnt',
	'system.gps.minutes',
	'system.gps.hours',
	'system.gps.day',
	'system.gps.month',
	'system.gps.year',
	'system.gps.seconds'
}


-- a unique log id for the sample
local logname = 'GPS'

-- Callback called when gps values changed
local gpscallback = function (gpsvalues)

	-- Display localization and fix date on successful fix
	if gpsvalues['system.gps.fix'] == 1 then
		log (logname, "INFO", "Localization find")
		log (logname, "INFO", "Position: lat=%s;long=%s (number of satellites: %d)", gpsvalues['system.gps.latitude'],
																					gpsvalues['system.gps.longitude'],
																					gpsvalues['system.gps.sat_cnt'])
		log (logname, "INFO", "GPS fix date: 20%d/%d/%d %d:%s:%d (GTM)", gpsvalues['system.gps.year'],
																		gpsvalues['system.gps.month'],
																		gpsvalues['system.gps.day'],
																		gpsvalues['system.gps.hours'],
																		gpsvalues['system.gps.minutes'],
																		gpsvalues['system.gps.seconds'])
	else
		-- No fix available
		log (logname, "INFO", "Localization in progress (%d satellites detected)",gpsvalues['system.gps.sat_cnt'])
	end
end

local function main ()
	log.setlevel("INFO")
	log (logname, "INFO", "GPS sample starting...")
	
	-- initialize devicetree before using it
	assert(device.init())
	
	-- add tracking vars to passive vars.
	for _, value in ipairs(gpsvars) do
		table.insert(gpspassivevars,value)
	end

	-- register the callback for fix, latitude and longitute values change.
	-- the date of the fix, the sattelite count are set as passive variables
	-- because we need to display theses values, but not to be notified of their change.
	-- In our case, it's very useful to avoid to be notified each second by the variable 'system.gps.seconds'
	-- The tracking variables are also set as passive variable, our callback need all theses values.
	-- If we don't add tracking variable to the passive vars, only the var that change will be pass to the callback
	assert(device.register(gpsvars, gpscallback, gpspassivevars))

end

sched.run(main)
sched.loop()
