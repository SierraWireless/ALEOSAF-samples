-------------------------------------------------------------------------------
-- This module provides geometric facilities for GPS positions analysis.
-- It defines point objects, geodesic surfaces, and common
-- methods operating on these.
-- @module geoloc

local M = { }
geoloc = M

-------------------------------------------------------------------------------
-- Points are the abstract datatypes representing a GPS position.
-- @type point
-- @field latitude
-- @field longitude
-- @field altitude
-- @field timestamp
local point = { __type='point' }
point.__index = point

-------------------------------------------------------------------------------
-- Point constructor.
--
-- @function   [parent=#geoloc] newpoint
-- @param      lat  the latitude
-- @param      long the longitude
-- @param      alt  (optional) the altitude
-- @param      ts   (optional) the timestamp at which the point has been collected
-- @return #point An object point
function M.newpoint(lat, long, alt, ts)
    checks('number', 'number', '?number', '?number')
    assert(-90<=lat and lat<=90)
    assert(-180<=long and long<=180)
    return setmetatable({
        latitude  = lat;
        longitude = long;
        altitude  = alt;
        timestamp = ts;
    }, point)
end

-------------------------------------------------------------------------------
-- Convert point into string.
--
-- @function [parent=#point] __tostring
-- @param self
-- @return #string
function point :__tostring()
    return  self.latitude..';'..self.longitude--string.format("%d;%d", self.latitude, self.longitude)
end

-- Precomputed helpers for distance
local pi_360              = math.pi/360
local pi_180_earth_radius = math.pi/180 * 6.371e6

-------------------------------------------------------------------------------
-- Compute approximate distance, in meters, between two points.
-- (Earth is considered spherical, and the distance between two points
-- small enough to approximate the arc between them as flat).
-- @function [parent=#geoloc] distance
-- @param #point p1 first point
-- @param #point p2 second point
-- @return #number Distance between p1 and p2, in meters.
function M.distance(p1, p2)
    checks('point', 'point')
    local x1, x2 = p1.longitude, p2.longitude
    local y1, y2 = p1.latitude,  p2.latitude
    local z1, z2 = p1.altitude,  p2.altitude
    local dx  = (x2-x1) * pi_180_earth_radius * math.cos((y2+y1)*pi_360)
    local dy  = (y2-y1) * pi_180_earth_radius
    local dz = z1 and z2 and z2-z1 or 0
    assert (dx*dx+dy*dy+dz*dz >= 0)
    assert ((dx*dx+dy*dy+dz*dz)^0.5 >= 0)
    log ('GEOLOC', 'DEBUG', "Found a distance of %dm between %s and %s", (dx*dx+dy*dy+dz*dz)^0.5 , tostring(p1), tostring(p2))
    return (dx*dx+dy*dy+dz*dz)^0.5
end

-------------------------------------------------------------------------------
-- Compute approximate speed, in km/h, between two timestamped points.
-- (Earth is considered spherical, and the distance between two points
-- small enough to approximate the arc between them as flat).
-- @param #point p1 first timestamped point
-- @param #point p2 second timestamped point
-- @return distance between p1 and p2, in km/h
-- @return nil, error_message.
function M.speed(p1, p2)
    local t1, t2 = p1.timestamp, p2.timestamp
    if not (t1 and t2) then
        return nil, 'no timestamps'
    end
    return M.distance(p1, p2) / math.abs(t1-t2) * 3.6
end

-------------------------------------------------------------------------------
-- point :distance (another_point) is a shortcut for
-- distance (point, another_point).
--
-- @function [parent=#point] distance
-- @param #point
-- @return #number
-- @usage apoint:distance(anotherpoint)
point.distance = M.distance


-------------------------------------------------------------------------------
-- point :speed (another_point) is a shortcut for speed (point, another_point).
--
-- @function [parent=#point] speed
-- @return #number
-- @usage apoint:speed(anotherpoint)
point.speed = M.speed


-------------------------------------------------------------------------------
-- @type area
--
-- Areas are subset of the GPS coordinates space. They are
-- characterised by their :contains(point) method, which determines
-- whether a point is inside or outside an area.
local area = { __type='area' }
area.__index = area

-- -----------------------------------------------------------------
-- Polygon helper: find out on which side of a line a point is
-- Return n>0 if p2 is on the left  of the line p0--p1
-- Return n<0 if p2 is on the right of the line p0--p1
-- Return 0   if p2 is on the line p0--p1
local function side(p0, p1, p2)
    return (p1.longitude-p0.longitude) * (p2.latitude-p0.latitude)
        - (p2.longitude-p0.longitude) * (p1.latitude-p0.latitude)
end

-- ----------------------------------------------------------------------------
-- Polygon helper: return the winding number for a point wrt a
-- polygon.
-- For a simple polygon (i.e. whose segments don't cross each other),
-- winding number is 0 iff the point is out of the polygon.
-- p: tested point
-- v: list of polygon vertices.
local function winding (p, v)
    checks('point', 'table')
    local wn = 0
    for i = 1, #v do
        local v_i, v_j = v[i>1 and i-1 or #v], v[i]
        if v_i.latitude <= p.latitude then
            if v_j.latitude>p.latitude and side(v_i,v_j, p) > 0 then wn=wn+1 end
        elseif v_j.latitude <= p.latitude and side (v_i, v_j, p) < 0 then wn=wn-1 end
    end
    return wn
end

-- ----------------------------------------------------------------------------
-- String -> points list converter.
-- find all occurences of "<number>; <number>" in string str_points,
-- convert them in a list of latitude/longitude records.
local function parse_points_list(str_points)
    --log ('GEOLOC', 'DEBUG', "parsing %s", str_points)
    --TODO: normalize to +/-90, +/-180
    local points = { }
    local num_regex = "(%-?%d+%.?%d*)"
    local point_regex = num_regex .. "[;,]%s*" .. num_regex
    for lat, long in str_points :gmatch (point_regex) do
        lat, long = tonumber(lat), tonumber(long)
        if lat and long then
            table.insert (points, M.newpoint(lat, long))
        end
    end
    return points
end

-- ----------------------------------------------------------------------------
-- Helpers determining whether a point is inside a shape.
-- @type inside
local inside = { }

---
-- @function [parent=#inside] circle
-- @param self
-- @param #point p
-- @return #boolean
function inside.circle(self, p)
    checks ('area', 'point')
    local d = self.center :distance (p)
    local is_inside = d <= self.radius
    log('GEOLOC', 'DEBUG', "%s, at %d meters from center %s of circle",
    is_inside and 'inside' or 'outside', d, tostring(self.center))
    return is_inside
end

---
-- @function [parent=#inside] rectangle
-- @param self
-- @param #point p
-- @return #boolean
function inside.rectangle(self, p)
    checks ('area', 'point')
    local corners = self.corners
    return
        corners[1].longitude<=p.longitude and p.longitude<=corners[2].longitude and
        corners[1].latitude<=p.latitude and y.longitude<=corners[2].latitude
end

---
-- @function [parent=#inside] poly
-- @param self
-- @param #point p
-- @return #boolean
function inside.poly(self, p)
    checks ('area', 'point')
    local rect, vertices = self.rectangle, self.poly
    -- Fast test: are we out of the envolopping rectangle?
    if p.longitude>rect.longitudeMax or p.longitude<rect.longitudeMin
    or p.latitude>rect.latitudeMax or p.latitude<rect.latitudeMin then
        return false
    end
    return winding (p, vertices) ~= 0
end

---
-- @function [parent=#inside] everywhere
-- @return #boolean true
function inside.everywhere() return true end

---
-- @function [parent=#inside] nowhere
-- @return #boolean false
function inside.nowhere() return false end

---
-- @function [parent=#inside] inversion
-- @param p
-- @return #boolean true
function inside.inversion(p)
    return not self.operand :contains (p)
end

---
-- @function [parent=#inside] intersection
-- @param #point p
-- @return #boolean
function inside.intersection(p)
    for _, area in pairs(self.operands) do
        if not area :contains(p) then return false end
    end
    return true
end

---
-- @function [parent=#inside] union
-- @param #point p
-- @return #boolean
function inside.union(p)
    for _, area in pairs(self.operands) do
        if area :contains(p) then
            return true
        end
    end
    return false
end

---
-- Addition between two areas return their union.
--
-- @function [parent=#area] __add
-- @param self
-- @param #area rigth
-- @return #area Their union
function area :__add(right)
    return setmetatable({kind='union', operands={self, right}}, area)
end

---
-- Multiplication between two areas return their intersection.
--
-- @function [parent=#area] __mul
-- @param self
-- @param #area rigth
-- @return #area Their intersection
function area :__mul(right)
    return setmetatable({kind='intersection', operands={self, right}}, area)
end

---
-- Sign inversion on an area return its complement.
--
-- @function [parent=#area] __unm
-- @param self
-- @param #area rigth
-- @return #area Their complement
function area :__unm(right)
    return setmetatable({kind='inversion', operand=self}, area)
end

---
-- Substraction between two areas return their difference.
--
-- @function [parent=#area] __sub
-- @param self
-- @param #area rigth
-- @return #area Their difference
function area :__sub(right) return self * (-right) end


-------------------------------------------------------------------------------
-- @function [parent=#area] contains
-- @param self
-- @param #point p
-- @return #boolean true if point p is inside the shape, false if point p is
--  outside the shape.
function area :contains (p)
    checks('area', 'point')
    local m = inside[self.kind]
    return inside[self.kind](self, p)
end

---
-- Area constructor helpers
-- @type build
local build = { }

---
-- @function [parent=#build] poly
-- @param self
-- @param #table Table of @{#point}.
function build.poly(self, points)
    local poly = parse_points_list (points)
    local rectangle = {
        longitudeMin =  180,
        longitudeMax = -180,
        latitudeMin  =   90,
        latitudeMax  =  -90 }
    for _, p in ipairs(poly) do
        local x, y = p.longitude, p.latitude
        if     x<rectangle.longitudeMin then  rectangle.longitudeMin=x
        elseif x>rectangle.longitudeMax then  rectangle.longitudeMax=x end
        if     y<rectangle.latitudeMin  then  rectangle.latitudeMin=y
        elseif y>rectangle.latitudeMax  then  rectangle.latitudeMax=y end
    end
    self.poly = poly
    self.rectangle = rectangle
end

---
-- @function [parent=#build] everywhere
-- @param self
-- @param #table Table of @{#point}.
function build.everywhere(self, points) end

---
-- @function [parent=#build] nowhere
-- @param self
-- @param #table Table of @{#point}.
function build.nowhere(self, points) end

---
-- @function [parent=#build] circle
-- @param self
-- @param #table Table of @{#point}.
function build.circle(self, points)
    local p = parse_points_list (points)
    local r = points :match "[0-9%.]+$" -- radius is the last number in the list
    assert(#p == 1, "Invalid circle center")
    assert(r, "Invalid circle radius")
    self.center = p[1]
    self.radius = tonumber(r)
end

---
-- @function [parent=#build] rectangle
-- @param self
-- @param #table Table of @{#point}.
function build.rectangle(self, points)
    local p = parse_points_list (points)
    if #p ~= 2 then error "Invalid rectangle corners" end
    if p[1].longitude>p[2].longitude then p[1].longitude, p[2].longitude = p[2].longitude, p[1].longitude end
    if p[1].latitude>p[2].latitude then p[1].latitude, p[2].latitude = p[2].latitude, p[1].latitude end
    self.upperleft = p[1]
    self.lowerright = p[2]
end

-------------------------------------------------------------------------------
-- Area constructor.
--
-- @function [parent=#geoloc] newarea
-- @param #string spec A string describing the area shape and measures.
-- It must have one of the following forms:
--  * a circle around a point with a given radius:
--      `"circle <center_latitude>;<center_longitude>;radius_in_meters"`
--  * an area delimited by a pari of latitudes and longitudes:
--      `"rectangle <latitude_1>;<longitude_1>;<latitude_2>;<longitude_2>"`
--  * a polygon delimited by a list of points:
--      `"poly <latitude_1>;<longitude_1>;...;<latitude_n>;<longitude_n>"`
--  * The whole surface of the planet: `"everywhere"`
--  * the empty surface, to which no point can  belong: `"nowhere"`
--
-- **Note** that "rectangles" aren't true rectangles: their sides must
-- have constant latitude and longitude. As a result, the constant-latitude
-- sides generally don't have the same length.
--
-- It is assumed that polygon sides don't cross over each other. If they do,
-- the result is unspecified.
--
-- @return #area An area object
-- @return #nil, #string error message.
function M.newarea(spec)
    checks('string')
    local kind, points = spec :lower() :match "^([a-z]*)%s*([%s%-0-9;,.]*)$"
    if not kind then
        return nil, "Invalid shape"
    end
    local buildk = build[kind]
    if not buildk then
        return nil, "Invalid shape kind"
    end
    local instance = { kind=kind }
    buildk(instance, points)
    setmetatable(instance, area)
    return instance
end

return M

-- ---------------------------------------------------------------------------
-- Winding algorithm:
--
-- Copyright 2001, softSurfer (www.softsurfer.com)
-- This code may be freely used and modified for any purpose
-- providing that this copyright notice is included with it.
-- SoftSurfer makes no warranty for this code, and cannot be held
-- liable for any real or imagined damage resulting from its use.
-- Users of this code must verify correctness for their application.
-- ----------------------------------------------------------------------------
