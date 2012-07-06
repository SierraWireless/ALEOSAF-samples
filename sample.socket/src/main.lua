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
-- Socket sample
--
local sched = require 'sched'
local log = require 'log'
local socket = require 'socket'

local logname = "SOCKET"

local function main ()
	log.setlevel("INFO")

	log(logname, "INFO", "Starting sample...")

	-- create and open a TCP socket and bind it to the localhost, at any port
	local server = assert(socket.bind("*", 0))
	-- find out which port ALEOS chose for us
	local _, port = server:getsockname()
	log(logname, "INFO", "TCP socket listening on port %s, waiting...", port)

	log(logname, "INFO", "Open a telnet connection on the device, for the %s port.", port)
	-- loop forever waiting for clients
	repeat
	
		-- wait for a connection from clients
		local client = server:accept()
		log(logname, "INFO", "Incoming connection accepted")
		
		-- On client connect, set a welcome message
		client:send("Welcome, you have 15s to type a line here: (Type 'stop' to close the sample)\n")
		
		-- wait 15s to for the line.
		client:settimeout(15)
		
		-- retreive the line
		local line, err = client:receive()

		if not err then
			-- Send a ack message to the client
			log(logname, "INFO", "Line correctly received: %s", line)
			client:send("Line received: "..line .. "\nClosing connection now\n")
		else
			log(logname, "INFO", "Error when receiving message: %s", err)
		end
		
		-- Close the current connection
		client:close()
		log(logname, "INFO", "Connection closed")
		
	until line == "stop"

	log(logname, "INFO", "Closing port")
	server:close()

	log(logname, "INFO", "Sample end")
	os.exit()
end

sched.run(main)
sched.loop()
