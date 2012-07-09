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
-- SMS sample
--
local log   = require 'log'
local os    = require 'os'
local sched = require 'sched'
local sms   = require 'sms'

--
-- Setting telephone numbers
--
local SMSRECIPIENTNUMBER = '9995551234'
local SMSSENDERNUMBER    = '9995551234'

--
-- SMS send settings
--
local MESSAGEFORMAT      = '7bits'
local MESSAGEPATTERN     = '.*you.*'
local TIMETOWAITFORREPLY = 40

--
-- Set up logging settings
--
local LOGMODULEAME = 'SMSSAMPLE'
local LOGSEVERITY  = 'INFO'

--------------------------------------------------------------------------------
-- Callback function for SMS messages received
local function whensmsisreceived(sender, message)
	log(LOGMODULEAME, LOGSEVERITY, 'Call back received from %s:%s', sender, message)
	local messagetosend = string.format('Hey, I just received this message: %s.', message)
	assert (sms.send(SMSRECIPIENTNUMBER, messagetosend, MESSAGEFORMAT))
	log(LOGMODULEAME, LOGSEVERITY, 'Call back anwsered to last message from %s.', sender)
end

-------------------------------------------------------------------------------
-- Operates SMS sending and retrieval using ALOES AF.
--
-- 1. Connect to the ReadyAgent to handle SMS requests.
-- 2. Register to receive SMS messages.
-- 3. Send SMS message.
-- 4. Receive SMS messages.
-- 5. Anwser them.
-- 6. Cleanup and exit.
--
-- @function [parent=#global] main
--
local function main ()

	-- Initiate logging
	log.setlevel(LOGSEVERITY)

	log(LOGMODULEAME, LOGSEVERITY, 'Starting SMS sample app')
	assert(sms.init())

	--
	-- Register to receive all SMS messages from any number, with any message
	-- content.
	--
	log(LOGMODULEAME, LOGSEVERITY, 'Register to receive all SMS messages')
	local smsregistrationid = assert (sms.register(whensmsisreceived))

	-- Send a SMS message
	log(LOGMODULEAME, LOGSEVERITY, 'Sending SMS message to %s, waiting for any SMS.', SMSRECIPIENTNUMBER)
	assert (sms.send(SMSRECIPIENTNUMBER, 'Hi, I am your lua app. You can send me messages.', MESSAGEFORMAT))

	-- Pause to receive messages
	sched.wait(TIMETOWAITFORREPLY)

	-- Unregister from receiving all msgs
	sms.unregister(smsregistrationid)

	--
	-- Register to receive SMS messages from a specific phone number
	--
	log(LOGMODULEAME, LOGSEVERITY, 'Register to receive messages only from %s.', SMSRECIPIENTNUMBER)

	-- Note the country code may not be in the received message
	smsregistrationid = assert (sms.register(whensmsisreceived, SMSRECIPIENTNUMBER))

	-- Send a SMS message
	log(LOGMODULEAME, LOGSEVERITY, 'Sending SMS message to %s.', SMSRECIPIENTNUMBER)
	assert (sms.send(SMSRECIPIENTNUMBER, 'Now, I only handle SMS from you.', MESSAGEFORMAT))

	-- Pause to receive messages
	sched.wait(TIMETOWAITFORREPLY)

	-- Unregister from receiving sms msgs
	sms.unregister (smsregistrationid)

	--
	-- Register to receive SMS messages that have specific content in msg body
	--
	log(LOGMODULEAME, LOGSEVERITY, 'Register to receive messages containing a pattern in msg body.')
	smsregistrationid = assert (sms.register(whensmsisreceived, nil, MESSAGEPATTERN))

	-- Send a SMS message
	log(LOGMODULEAME, LOGSEVERITY, 'Sending SMS message to %s.', SMSRECIPIENTNUMBER)
	local messagetosend = string.format("If you send me a SMS matching '%s' Lua pattern, I will answer.", MESSAGEPATTERN)
	assert (sms.send(SMSRECIPIENTNUMBER, messagetosend, MESSAGEFORMAT))

	-- Pause to receive messages
	sched.wait(TIMETOWAITFORREPLY)

	-- Unregister from receiving sms msgs
	sms.unregister (smsregistrationid)

	--
	-- Exiting nicely, with status code 0 for normal termination
	--
	log(LOGMODULEAME, LOGSEVERITY, 'End of SMS sample.')
	log(LOGMODULEAME, LOGSEVERITY, 'Exiting')
	os.exit(0)
end

--------------------------------------------------------------------------------
-- Schedule the main function, and launch the scheduler main loop
sched.run(main)
sched.loop()
