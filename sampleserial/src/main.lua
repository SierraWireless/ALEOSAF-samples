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
-- Serial Access API sample
-- Reserves the serial port, opens the port, reads char on the serial port and provides echo.
-- Send "Ctrl+D" on the serial port to exit the sample

local devicetree = require "devicetree"
local sched      = require "sched"
local os         = require "os"
local log        = require "log"
local system     = require "system"
local string     = require "string"
local serial     = require "serial"

local logname          = "SERIAL"
local RESERVEVARPATH   = "system.aleos.reserve.ser0"
local RESERVEVARSTATUS = 1

--
-- Serial port configuration
--
local SERIALPORTNAME = "/dev/ttyS0"
local SERIALPORTCONFIGURATION = {
	baudRate    = 115200,
	flowControl = "none",
	numDataBits = 8,
	parity      = "none",
	numStopBits = 1
}

--------------------------------------------------------------------------------
-- Reserve serial port.
-- Check if the serial port has been reserved for our use,
-- if not, reserve it and reboot to get control.
-- **WARNING** This function can reboot the device.
local function reserveserialport (devtree)

	-- Get the actual value of the setting, the value `1` means the serial port is already reserved.
	local serial_available = assert (devtree.get(RESERVEVARPATH))
	if serial_available ~= RESERVEVARSTATUS then
		log (logname,"WARNING","Serial port not available, reserving it now...")

		-- Set the setting to "1" and reboot
		local result = assert (devtree.set(RESERVEVARPATH, RESERVEVARSTATUS))
		log (logname,"WARNING", "Rebooting now...")
		system.reboot("Reserving serial port for AAF.")

		-- Stop here until the reset occurs
		sched.wait(30)
	end
	log (logname,"INFO","Serial Port has been reserved for Serial Access sample use.")
end

--------------------------------------------------------------------------------
-- Serial Sample - Examples of the serial port API usage
--
-- @function [parent=#global] main
--
function main ()

	-- Set log level to info to see all following links
	log.setlevel("INFO")
	log(logname,"INFO","Starting...")

	-- Init device tree and system libraries before using it
	assert(devicetree.init())
	assert(system.init())

	-- Reserve the serial port if needed
	reserveserialport(devicetree)

	-- Openning serial port with default settings
	log(logname,"INFO","Opening serial port...")
	local serialdev = assert(serial.open(SERIALPORTNAME, SERIALPORTCONFIGURATION))

	-- Write a welcome message on the serial
	log(logname,"INFO","Serial communication openned!")
	assert(serialdev:write("Serial communication openned!\r\n"))

	--Loop to read incoming char until the char "Ctrl+D" is detected
	repeat

		-- Read char by char
		local char = serialdev:read(1)

		-- Rewrite every char to provide echo
		serialdev:write(char)

	-- Check if the recivied char is equal to Ctrl+D char reprensenting by the ASCII code 04
	until char == string.char(04)

	-- Ending the application
	serialdev:write("\r\nExiting")
	log (logname,"INFO","Exiting...")

	-- close the serial instance
	serialdev:close()

	-- Stop the application
	os.exit (0)
end

--------------------------------------------------------------------------------
-- Schedule the main function, and launch the scheduler main loop
sched.run(main)
sched.loop()
