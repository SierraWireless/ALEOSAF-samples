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
local SMS_RECIPIENT_NUMBER = '9995551234'
local SMS_SENDER_NUMBER    = '9995551234'

--
-- SMS send settings
--
local MESSAGE_FORMAT      = '7bits'
local MESSAGE_PATTERN     = '.*you.*'
local TIME_TO_WAIT_FOR_REPLY = 40

local LOG_NAME = 'SMSSAMPLE'

--------------------------------------------------------------------------------
-- Callback function for SMS messages received
local function whensmsisreceived(sender, message)
    log(LOG_NAME, 'INFO', 'Call back received from %s:%s', sender, message)
    local messagetosend = string.format('Hey, I just received this message: %s.', message)
    assert (sms.send(SMS_RECIPIENT_NUMBER, messagetosend, MESSAGE_FORMAT))
    log(LOG_NAME, 'INFO', 'Call back anwsered to last message from %s.', sender)
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
    log.setlevel('INFO')

    log(LOG_NAME, 'INFO', 'Starting SMS sample app')
    assert(sms.init())

    --
    -- Register to receive all SMS messages from any number, with any message
    -- content.
    --
    log(LOG_NAME, 'INFO', 'Register to receive all SMS messages')
    local smsregistrationid = assert (sms.register(whensmsisreceived))

    -- Send a SMS message
    log(LOG_NAME, 'INFO', 'Sending SMS message to %s, waiting for any SMS.', SMS_RECIPIENT_NUMBER)
    assert (sms.send(SMS_RECIPIENT_NUMBER, 'Hi, I am your lua app. You can send me messages.', MESSAGE_FORMAT))

    -- Pause to receive messages
    sched.wait(TIME_TO_WAIT_FOR_REPLY)

    -- Unregister from receiving all msgs
    sms.unregister(smsregistrationid)

    --
    -- Register to receive SMS messages from a specific phone number
    --
    log(LOG_NAME, 'INFO', 'Register to receive messages only from %s.', SMS_RECIPIENT_NUMBER)

    -- Note the country code may not be in the received message
    smsregistrationid = assert (sms.register(whensmsisreceived, SMS_RECIPIENT_NUMBER))

    -- Send a SMS message
    log(LOG_NAME, 'INFO', 'Sending SMS message to %s.', SMS_RECIPIENT_NUMBER)
    assert (sms.send(SMS_RECIPIENT_NUMBER, 'Now, I only handle SMS from you.', MESSAGE_FORMAT))

    -- Pause to receive messages
    sched.wait(TIME_TO_WAIT_FOR_REPLY)

    -- Unregister from receiving sms msgs
    sms.unregister (smsregistrationid)

    --
    -- Register to receive SMS messages that have specific content in msg body
    --
    log(LOG_NAME, 'INFO', 'Register to receive messages containing a pattern in msg body.')
    smsregistrationid = assert (sms.register(whensmsisreceived, nil, MESSAGE_PATTERN))

    -- Send a SMS message
    log(LOG_NAME, 'INFO', 'Sending SMS message to %s.', SMS_RECIPIENT_NUMBER)
    local msg = string.format("If you send me a SMS matching pattern %q I will answer.",
        MESSAGE_PATTERN)
    assert (sms.send(SMS_RECIPIENT_NUMBER, msg, MESSAGE_FORMAT))

    -- Pause to receive messages
    sched.wait(TIME_TO_WAIT_FOR_REPLY)

    -- Unregister from receiving sms msgs
    sms.unregister (smsregistrationid)

    --
    -- Exiting nicely, with status code 0 for normal termination
    --
    log(LOG_NAME, 'INFO', 'End of SMS sample.')
    log(LOG_NAME, 'INFO', 'Exiting')
    os.exit(0)
end

--------------------------------------------------------------------------------
-- Schedule the main function, and launch the scheduler main loop
sched.run(main)
sched.loop()
