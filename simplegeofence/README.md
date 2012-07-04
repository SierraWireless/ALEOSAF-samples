# Introduction

This document will guide you in creating a geofencing application that will operate in the GPS and Sierra Wireless ALEOS AF enabled modems. A geofence defines an area that can be monitored to determine when a vehicle exits or enters the defined area. The geofence area is specified using GPS points or a GPS point and a distance. As the GPS location is updated by changes in latitude and longitude variables, the current location can be checked to determine if it is inside or outside of the defined fence. The functions to facilitate creating geofences and determining if a point is in or out of a fence area are in the geolocation library, `geoloc`.

For the code snippets used in examples below, the following modules are needed:

```lua
local sched      = require 'sched'      -- Lua scheduling and synchronization library
local geoloc     = require 'geoloc'     -- Geolocation library
local devicetree = require 'devicetree' -- Access to the device's variables
```

# Specifying a geofence area

A geofence area can be specified as a circle, rectangle, or polygon. You can also specify **'everywhere'** to mean that the whole earth is inside the fence, or **'nowhere'** to imply that there is no way to be inside a fence.

## Circle

A circular fence is specified by a point and a radius. The argument string to create a circular fence is:

```lua
circle_fence_string = "circle center_latitude; center_longitude; radius_in_meters"
```

## Rectangle

A rectangular fence is specified by a pair of latitudes and longitudes. The argument string to create a rectangular fence is:

```lua
rectangular_fence_string = "rectangle latitude_1; longitude_1; latitude_2; longitude_2"
```

## Polygon

A polygonal fence is specified by a list of points. At least three points are required to define the fence. The argument string to create a polygonal fence is:

```lua
polygonal_fence_string = "poly latitude_1; longitude_1;...; latitude_n; longitude_n"
```

## everywhere and nowhere

In the event it is desired to declare that a vehicle is "always inside a fence", simply use the fence string:
**'everywhere'**

And, likewise, to declare that the vehicle is never inside a fence, use:
**'nowhere'**

These two fences can be useful to exercise your code to simulate moving into and out of a fence by changing the fence type between **everywhere** and **nowhere**.

## Creating a fence

A fence is created with the `geoloc.newarea` function.

```lua
local my_fence, err_msg = geoloc.newarea (fence_string)
```

Where `fence_string` is one of the above fence forms.

# Location Updates and the Callback function

## Register the GPS variables

To receive GPS updates for your location, register to receive the GPS variables for latitude and longitude.

```lua
function main()
assert(devicetree.init())
```

The register variable function takes a list of variables and a callback function to handle the updates. This callback function, `check_for_fence_breaches`, is called each time an update occurs and will determine if the updated location has entered or exited the fence.

```lua
local gps_vars = { 'aleos.gps.latitude','aleos.gps.longitude','aleos.gps.fix' }
devicetree.register (gps_vars, check_for_fence_breaches)
```

**Note** that the `register` function causes an immediate update to occur for each of the listed variables.

## The callback function
The callback function receives the GPS updates, which could occur as often as once a second, and takes the appropriate actions based on the new position.
For this callback function, we'll need a state table that will contain the variables that will be used to determine if the vehicle has made a transition across the fence boundaries.

### The state table

This table will keep the current state of the application.

```lua
local state = {
	fence = geoloc.newarea 'everywhere';
	last_reported_position = false;
	was_in_fence = true;
	lat = 0;
	long = 0;
	fix = 0;
}
```

Where:

* `fence` is the current fence area. Later, a function will be implemented to allow the fence to be set.
* `last_reported_position` is the last GPS point reported and is used to determine if the vehicle has moved beyond a minimum distance in order to be considered as a change. When a vehicle is sitting still, the GPS coordinates constantly "jitter", indicating small movements. So a new position is tested against the last position to determine if the vehicle is really moving.
* `was_in_fence` notes whether the last position reported was inside or outside the fence. `true` = inside the fence.
* `lat` and `long` are the current latitude and longitude values. If an update contains only the latitude, for example, then the `state.long` value did not change and is valid for the current position.
* `fix` is the current state of the GPS fix which indicates whether valid location values are being received. Values are:
`0` = No fix, while values > 0 indicate that enough satellite signals have been acquired to calculate valid positions.

### Initial callback function implementation

A simple implementation that demonstrates how to detect movements in and out of a fence. You can find it in module `simplegeofence`, the function is called `check_for_fence_breaches`.
```

### The control variables

Now, add tracking the vehicle. A control table is added for the necessary variables.
The `control` table contains several variables that are used to determine the behavior of the application.

```lua
local control = {
	started = true;
	always_track = false;
	track_outside = true;
	delta = 100;
}
```

Where:

* `started` notes whether fence activity, the exits and entries, should be reported or not. `true` = yes.
* `always_track` notes whether position changes should always be reported, both inside and outside the fence. `true` = yes.
* `track_outside` notes that a change in position should be reported when outside the fence.
* `delta` is the distance in meters that a vehicle needs to move before it is considered as a change in position.

### Callback function with the control variables implemented

There is an example available in module `simplegeofence`, with the `check_for_fence_breaches` function. In this example, the `control.started` variable has been added and is checked to see if any reporting is desired. If its value is `false`, then the function exits without checking anything else. Following the tests for fence crossing, if tracking is desired for the current state of being in or out of the fence, the current position is checked to see if it has moved a distance greater than `delta`. If it has moved greater than `delta`, then the variable, `state.last_reported_position`, is updated and the desired action is executed.
