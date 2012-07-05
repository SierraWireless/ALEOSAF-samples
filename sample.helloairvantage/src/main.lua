--
-- Hello app communication with Air Vantage Platform
--
local airvantage	= require "airvantage"  -- Library to access AirVantage
local device		= require "devicetree"
local sched         = require "sched"
local math          = require "math"
local log           = require "log"

local logname       = "HELLO_AV"


-------------------------------------------------------------------------------
-- The callback function that receives the variable updates
-- and logs the variable path and  value
-- Need to return "ok" at the end
local function integercallback (assetInstance, value, path)
	log(logname, "INFO", "integercallback: path = %s, value = %s.", tostring(path), tostring(value))
	return "ok"
end

-------------------------------------------------------------------------------
-- The callback function that receives the commands
-- and prints the variable path and the table value
-- Need to return "ok" at the end
local function printcallback (assetInstance, commandArgumentsList, pathcommandsprintmessage)
	log(logname, "INFO", "printcallback: path_commands_PrintMessage: %s, commandArgumentsList[1]: %s.",
	pathcommandsprintmessage, commandArgumentsList[1])
	return "ok"
end


local function main ()

	-- Configure log level
	log.setlevel("INFO")

	local server, status
	---------------------------------------------------------------------------
	-- Initialize the link to get and set ALEOS information
	device.init()

	-- Initialize the link to the ReadyAgent
	airvantage.init()

	-- Create a new instance of an asset.
	local helloasset = assert (airvantage.newAsset("HelloAirVantage"))

	-- Log device serial number for debug purpose
	log(logname, "INFO", "config.agent.deviceId: %s", tostring(device.get ("config.agent.deviceId")))

	-- Register Callback Functions Against Command Branch
	-- Note the path and name of the command in the tree
	helloasset.tree.commands.PrintMessage = printcallback

	-- Register Data Elements Against Branches/Path
	-- Note the path and name of the setting in the tree
	helloasset.tree.downlink = {}
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

	-- Put a state into the queue
	helloasset:pushdata("uplink", {State=1}, "now")

	-- Repeat forever
	log(logname, "INFO", "Starting Loop")
	while true do
		-- Set the variable values that we want to send
		count = count + 1
		local randomnumber = math.random()
		local stringvalue = "Hello AirVantage: "
		log(logname, "INFO", "Sending new data: messagecount = %s, randomnumber = %s, stringvalue = %s.",tostring(count), tostring(randomnumber), stringvalue)

		-- Push them into hourly queue
		helloasset:pushdata("uplink", {MessageCount=count, FloatingPoint=randomnumber, String=stringvalue}, "hourly")

		-- Connect to the server and push all the data up
		airvantage.triggerpolicy("*")

		-- Sleep 30 seconds
		sched.wait(30)
	end
end

sched.run(main)
sched.loop()
