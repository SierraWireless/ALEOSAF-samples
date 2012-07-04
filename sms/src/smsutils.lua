---
-- SMS sample
-- @module smsutils
--
local sched = require 'sched'
local sms   = require 'sms'
local os    = require "os"
local M = {}

---
-- Phone number to send SMS msgs to
--
-- @field [parent=#smsutils] send_sms_to
M.send_sms_to = '9995551234'

---
-- Phone number filter for receiving
--
-- @field [parent=#smsutils] recv_sms_from
M.recv_sms_from = '9995551234'

local recv_pattern  = 'Delivered'   -- pattern filter for receiving

--------------------------------------------------------------------------------
-- Callback function for SMS messages received
local function when_sms_msg_received(sender, message)
	print ("Received SMS msg from: ", sender)
	print ("Msg: ", message)
end

--------------------------------------------------------------------------------
-- Register to receive all SMS messages
-- from any number, with any message content
--
-- @function [parent = #smsutils ] example_register_to_receive_all_sms_msgs
-- @return Id (can be any Lua non-nil value) should be used only to call #sms.unregister.
-- @return #nil, #string Nil followed by an error message otherwise.
function M.example_register_to_receive_all_sms_msgs ()
	print ('Register to receive all SMS messages')
	local reg_sms_id = assert (sms.register(when_sms_msg_received))
	return (reg_sms_id) -- ID is needed to unregister
end

--------------------------------------------------------------------------------
-- Register to receive SMS messages from a specific phone number
--
-- @function [parent = #smsutils ] example_register_for_sms_msgs_from_a_sender
-- @return Id (can be any Lua non-nil value) should be used only to call #sms.unregister.
-- @return #nil, #string Nil followed by an error message otherwise.
function M.example_register_for_sms_msgs_from_a_sender ()
	print ('Register to receive messages from a sender')
	-- Note the country code may not be in the received message
	local reg_sms_id = assert (sms.register(when_sms_msg_received, M.recv_sms_from))
	return (reg_sms_id) -- ID is needed to unregister
end

--------------------------------------------------------------------------------
-- Register to receive SMS messages that have specific content in msg body
--
-- @function [parent = #smsutils ] example_register_for_msg_content
-- @return Id (can be any Lua non-nil value) should be used only to call #sms.unregister.
-- @return #nil, #string Nil followed by an error message otherwise.
function M.example_register_for_msg_content ()
	print ('Register to receive messages containing a pattern in msg body')
	local reg_sms_id = assert (sms.register(when_sms_msg_received, '', recv_pattern))
	return (reg_sms_id) -- ID is needed to unregister
end

--------------------------------------------------------------------------------
-- Send an SMS message
--
-- @function [parent = #smsutils ] example_send_sms
--
function M.example_send_sms ()
	local smsPhone = M.send_sms_to
	local sendmsg = 'Message from Lua app...'
	local msgFormat_7bit = '7bits'

	print ('Sending SMS message to ', smsPhone)
	assert (sms.send(smsPhone, sendmsg, msgFormat_7bit))
end
return M
