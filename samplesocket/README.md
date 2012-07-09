Socket Sample
=======================

A simple example of socket module, openning a TCP port on the device and wait for connections.

How to use
----------

Launch the sample on the device. Then users can connect to the device, using the given port.
The most common way to start a connection is to use the telnet command.
On the connection opening, a welcome message appears, you have 15s to type a line and press enter.
After receiving the line, the sample will close the connection, and waiting for another one.
If you type `"stop"` the sample will terminate by closing the port.

**Limitation** : This sample doesn't handle more than one connection at once.

