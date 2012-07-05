SMS Sample app
==============

A brief example of how to send SMS with *ALEOS AF*.

It just uses *ALEOS AF* to send a SMS at the specified number the process is reported step by step.

Configuration
-------------
The application runs on its own, but you have to set two parameters beforehand. Edit `main.lua` with the right phone numbers at the top of the `main()` function.
```lua
--
-- Setting telephone numbers
--
smsutils.send_sms_to =   '9995551234'
smsutils.recv_sms_from = '9995551234'
``` 
