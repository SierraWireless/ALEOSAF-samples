--
-- ALEOS Variable Access sample.
-- (c) Sierra Wireless April 2012
--
local devicetree     = require 'devicetree'
local sched          = require 'sched'
local variableaccess = require 'variableaccess'

--------------------------------------------------------------------------------
-- Initialize the devicetree module, run all examples, cleanup and exit.
function main ()
	assert (devicetree.init())
	sched.wait(1)

	variableaccess.example_read_variables()
	sched.wait(1)

	variableaccess.example_set_variables()
	sched.wait(1)

	local din_id = variableaccess.example_monitor_variable()
	sched.wait(1)

	variableaccess.example_monitor_several_variables()
	sched.wait(1)

	variableaccess.example_monitor_passive_variables()
	sched.wait(1)

	print ("End of sample, cleaning up")
	devicetree.unregister (din_id)
	-- gps subscription already cancelled.

	sched.wait(2)

	print ("Exiting")
	os.exit(0) -- status code 0 = normal termination
end

--------------------------------------------------------------------------------
-- Schedule the main function, and launch the scheduler main loop
sched.run(main)
sched.loop()
