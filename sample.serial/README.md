Serial Sample app
==============

A brief example of how to use the serial module from the execution environement.
With a serial cable, the sample application can exange data with a computer.

Step to use
---------

1. Plug a serial cable beteween the computer and the device.
2. Open an hyperterminal with following configuration : 
    * baudRate=115200
    * flowControl = 'none'
    * numDataBits=8
    * parity='none'
    * numStopBits=1
3. Run the sample on the device
4. Now you can type some text in the hyperterminal and see the sample performing echo and logging
5. Send "Ctrl+D" character to the sample to end it
