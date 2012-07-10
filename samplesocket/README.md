Socket Sample
=======================

A simple example of socket module, openning a TCP port on the device and wait for connections.

How to use
----------

1. Launch the sample on the device. 
2. A port is given, users can connect to the device using it.
The most common way to start a connection is to use the telnet command.
3. On the connection opening, a welcome message appears, you have 15s to type a line and press enter.
4. After receiving the line, the sample will close the connection, and waiting for another one.
5. If you type `"stop"` the sample will terminate by closing the port.

**Limitation** : This sample doesn't handle more than one connection at once.

