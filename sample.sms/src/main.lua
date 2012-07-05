---
-- SMS sample
local sched    = require 'sched'
local sms      = require 'sms'
local smsutils = require 'smsutils'

--------------------------------------------------------------------------------
-- Connect to the ReadyAgent to handle SMS requests.
-- Register to receive SMS messages.
-- Send SMS message.
-- Receive SMS messages.
-- cleanup and exit.

local function main ()

	--
	-- Setting telephone numbers
	--
	smsutils.send_sms_to =   '9995551234'
	smsutils.recv_sms_from = '9995551234'

	print ("Starting SMS sample app")
	assert(sms.init())
	sched.wait(1)

	local reg_sms_id = smsutils.example_register_to_receive_all_sms_msgs ()
	sched.wait(1)

	smsutils.example_send_sms ()
	sched.wait(30)     -- pause to receive messages
	sms.unregister (reg_sms_id)    -- unregister from receiving all msgs

	reg_sms_id = smsutils.example_register_for_sms_msgs_from_a_sender ()
	sched.wait(1)

	smsutils.example_send_sms ()
	sched.wait(30)     -- pause to receive messages
	sms.unregister (reg_sms_id)    -- unregister from receiving sms msgs

	reg_sms_id = smsutils.example_register_for_msg_content ()
	sched.wait(1)

	smsutils.example_send_sms ()
	sched.wait(30)     -- pause to receive messages
	sms.unregister (reg_sms_id)    -- unregister from receiving sms msgs

	print ("End of SMS sample")
	print ("Exiting")
	os.exit(0) -- status code 0 = normal termination
end

--------------------------------------------------------------------------------
-- Schedule the main function, and launch the scheduler main loop
sched.run(main)
sched.loop()
