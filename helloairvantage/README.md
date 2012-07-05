Introduction
============
This document explains functionalities and how to run the AirVantage HelloWorld sample.

Functionalities
===============
The AirVantage HelloWorld sample show all the way to communicate between the AirVantage Cloud Platform and the embedded software.

The following part describe the different datas exchanged in this sample.

### Data send to the AirVantage Cloud Platform

Data send once:

* *State* : Set to 1 when the application start.

Data send every 30s

* *Message Count* : A variable that count the number of connection to the portal. Start at 0 when the application is launched and will always increase.
* *Floating Point* : A random decimal number generated before each communication
* *String* : the "Hello Airvantage" constant string

### Data receive from the AirVantage Cloud Platform

* `print` command, on reception will print a log with the given message
* `integer` setting, on reception will print the given integer in the log

How to run
==========

**This part assume you are familiar with the concepts explain in the getting started document.**

1. Import the project in the Developer Studio for ALEOS
    1. In the Import dialog select *"Existing Project into Workspace"* kind of import
    1. Select the downloaded archive file
1. Create a new connection to connect to your device in the Remote System Explorer perspective
1. Create a Launch configuration to launch the project on your device
1. Export the HelloAirVantage project using *"AirVantage Application Package"* kind of export
1. Upload the resulted archive on the AirVantage Cloud Platform
1. Don't forget to publish your new application
1. Create your system adding both applications ALEOS 4.2.5 and AirVantage HelloWorld
1. Activate your system
1. Before launching the application in the Developer Studio check following points in AceManager
    1. Be sure AAF is enable
    1. Be sure you have a SIM card and your are correctly connected to the GSM network
1. Launch the application, you can see the logs and see exchanged data on the AirVantage Cloud Platform.
