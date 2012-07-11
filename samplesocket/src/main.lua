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
local log    = require "log"
local os     = require "os"
local sched  = require "sched"
local socket = require "socket"

local LOG_NAME = "SOCKET"
local QUIT     = "stop"

local function main ()

    log.setlevel("INFO")
    log(LOG_NAME, "INFO", "Starting sample...")

    -- Create and open a TCP socket and bind it to the localhost, at any port
    local server = assert(socket.bind("*", 0))

    -- Find out which port ALEOS chose for us
    local localaddress, port = server:getsockname()
    log(LOG_NAME, "INFO", "TCP socket listening on port %d, please connect a telnet client to it.", port)

    -- Wait for a connection from clients
    local client = server:accept()
    log(LOG_NAME, "INFO", string.format("Incoming connection accepted.\nType '%s' to close the sample\n", QUIT))

    server:close() -- close the server, so that no more connection will be accepted

    client:settimeout(15) -- send and receive operations will timeout after 15s

    -- Loop forever waiting for clients
    client:send(string.format("Type %s to quit.\n", QUIT))
    repeat
        client:send("Welcome, you have 15s to type a line here: ") -- welcome message to client
        local line, err = client:receive() -- read a line from client (15s timeout still applies)
        if not err then -- Success
            log(LOG_NAME, "INFO", "Line correctly received: '%s'.", line)
            client:send(string.format("Line received: '%s'.\n", line))
        else
            log(LOG_NAME, "INFO", "Error when receiving message: %s", err)
        end

    until line == QUIT

    -- Close the current connection
    client:close()
    log(LOG_NAME, "INFO", "Connection closed, sample terminated.")
    os.exit()
end

sched.run(main)
sched.loop()
