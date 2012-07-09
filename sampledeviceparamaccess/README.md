Device Parameter Access
=======================

A simple example of ALEOS variable access, usually ALEOS varialble are managed using AceManger, 
but this sample show how you can access programmatically from ALEOS AF to ALEOS variables.

This sample is responsible of:
* Get ALEOS variable values
* Set ALEOS variable value
* Register callback to be notified of a ALEOS variable change
    * Track one variable
    * Track several variables
    * Track a node's variables
    * Track variables with passive variables

**WARNING**! This sample may change your APN, and break your over the air data connection.
If you don't want the sample to change your APN setting, comment associed code before launching the sample

**INFO** As this sample track RSSI value changement, you can disconnect and reconnect antena to change RSSI.