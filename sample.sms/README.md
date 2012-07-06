SMS Sample app
==============

A brief example wich will briefly discuss with you using *SMS* sent using *ALEOS AF*.

It just uses *ALEOS AF* to send and answer SMS at/from a specified number. The process is reported step by step.

1. Connect to the ReadyAgent to handle SMS requests.
2. Register to receive SMS messages.
3. Send SMS message.
4. Receive SMS messages.
5. Cleanup and exit.

Configuration
-------------
For the application to run properly, you should set two parameters beforehand. Edit `main.lua` with the right phone numbers at the top of the `main.lua`.
```lua
--
-- Setting telephone numbers
--
local SMSRECIPIENTNUMBER = '9995551234'
local SMSSENDERNUMBER    = '9995551234'
```

You can also change default answer time out,  by editing `TIMETOWAITFORREPLY`, in the SMS settings section.

