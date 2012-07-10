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
-- Hello app communication with Air Vantage Platform
--
local airvantage    = require "airvantage"  -- Library to access AirVantage
local devicetree    = require "devicetree"
local sched         = require "sched"
local math          = require "math"
local log           = require "log"

local LOG_NAME       = "HELLO_AV"

-------------------------------------------------------------------------------
-- The callback function that receives the variable updates
-- and logs the variable path and  value
-- Need to return "ok" at the end
local function integercallback (assetInstance, value, path)
	log(LOG_NAME, "INFO", "integercallback: path = %s, value = %s.", tostring(path), tostring(value))
	return "ok"
end

-------------------------------------------------------------------------------
-- The callback function that receives the commands
-- and prints the variable path and the table value
-- Need to return "ok" at the end
local function printcallback (assetInstance, commandArgumentslist, pathcommandsprintmessage)
	log(LOG_NAME, "INFO", "Received a PrintMessage command, with message '%s'.",
	    commandArgumentslist[1])
	return "ok"
end

---
-- @function [parent=#global] main
--
local function main ()

	log.setlevel("INFO") -- Set log verbosity
	devicetree.init()    -- Access to device variables
	airvantage.init()    -- Asset management module

	-- Create a new asset instance.
	local helloasset = assert (airvantage.newAsset("HelloAirVantage"))

	-- Log device serial number for debug purpose
	log(LOG_NAME, "INFO", "config.agent.deviceId: %s", tostring(device.get ("config.agent.deviceId")))

	-- By registering this command, we ensure that `printcallback()` will be
	-- called on the device every time a `"PrintMessage"` command is sent to
	-- this asset by an AirVantage server.
	helloasset.tree.commands.PrintMessage = printcallback

    -- By registering this command, we ensure that `integercallback()` will be
    -- called on the device every time an AirVantage server sends some data
    -- to this asset with the path `"downlink.Integer"`. As the name implies,
    -- the callback expects the data value to be an integer.
	helloasset.tree.downlink = { }
	helloasset.tree.downlink.Integer = integercallback

	-- Start the asset to enable sending and receiving data.
	assert (helloasset:start(), "Can't register Agent")
	sched.wait(10)

	-- We're all set up now to send and receive data.
	-- Time to do some work!
	---------------------------------------------------------------------------

	-- Initialize random number generator and message count
	math.randomseed(os.time())
	local count = 0

	-- Upload data "State=1" to the server
	helloasset:pushdata("uplink", {State=1}, "now")

    -- This loop will generate a random number every 30 seconds, and immediately
    -- upload it to the server.
    local function random_num_every_30s()
        while true do
            local num = math.random()
            log(LOG_NAME, 'INFO', "Uploading FloatingPoint = %i", num)
            helloasset:pushdata("uplink.FloatingPoint", num, 'now')
        end
    end
    sched.run (random_num_every_30s) -- run in a parallel thread

    -- This loop will generate a string minute, and accumulate it in a staging
    -- table; the table's content will be uploaded to the server every hour,
    -- thous limiting the number of wireless connections.
    --
    -- This separation between data acquisition and reporting is achieved thanks
    -- to pushdata's `policy` parameter, here set to `"hourly"`.
    --
    -- WARNING: Here the data are timestamped by the device, at acquisition time.
    -- If the device's clock is not set correctly, the data retrieved on the
    -- server will also have incorrect timestamps. 
    local function string_every_minute()
        while true do
            local str = "String acquired at "+os.date()
            log(LOG_NAME, 'INFO', "Accumulating a string")
            helloasset:pushdata("uplink", { String=str, timestamp=os.time() }, 'hourly')
        end
    end
    sched.run (string_every_minute) -- run in a parallel thread
end

sched.run(main)
sched.loop()
