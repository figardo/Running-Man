local surface_SetDrawColor = surface.SetDrawColor
local surface = surface
local math_max = math.max
local math_abs = math.abs
local math_rad = math.rad
local math_cos = math.cos
local math_sin = math.sin
local table_insert = table.insert
local math_floor = math.floor
local ipairs = ipairs
local surface_DrawPoly = surface.DrawPoly

-- https://gist.github.com/theawesomecoder61/d2c3a3d42bbce809ca446a85b4dda754
-- used for drawing the scoreboard outline corners

-- Draws an arc on your screen.
-- startang and endang are in degrees,
-- radius is the total radius of the outside edge to the center.
-- cx, cy are the x,y coordinates of the center of the arc.
-- roughness determines how many triangles are drawn. Number between 1-360; 2 or 3 is a good number.
function draw.Arc(cx,cy,radius,thickness,startang,endang,roughness,color)
	surface_SetDrawColor(255, 255, 255, 100)
	surface.DrawArc(surface.PrecacheArc(cx,cy,radius,thickness,startang,endang,roughness))
end

function surface.PrecacheArc(cx,cy,radius,thickness,startang,endang,roughness)
	local triarc = {}
	-- local deg2rad = math.pi / 180

	-- Define step
	roughness = math_max(roughness or 1, 1)
	local step = roughness

	-- Correct start/end ang
	startang, endang = startang or 0, endang or 0

	if startang > endang then
		step = math_abs(step) * -1
	end

	-- Create the inner circle's points.
	local inner = {}
	local r = radius - thickness
	for deg = startang, endang, step do
		local rad = math_rad(deg)
		-- local rad = deg2rad * deg
		local ox, oy = cx + (math_cos(rad) * r), cy + (-math_sin(rad) * r)
		table_insert(inner, {
			x = ox,
			y = oy,
			u = (ox - cx) / radius + .5,
			v = (oy - cy) / radius + .5,
		})
	end

	-- Create the outer circle's points.
	local outer = {}
	for deg = startang, endang, step do
		local rad = math_rad(deg)
		-- local rad = deg2rad * deg
		local ox, oy = cx + (math_cos(rad) * radius), cy + (-math_sin(rad) * radius)
		table_insert(outer, {
			x = ox,
			y = oy,
			u = (ox - cx) / radius + .5,
			v = (oy - cy) / radius + .5,
		})
	end

	-- Triangulize the points.
	for tri = 1, #inner * 2 do -- twice as many triangles as there are degrees.
		local p1,p2,p3
		p1 = outer[math_floor(tri / 2) + 1]
		p3 = inner[math_floor((tri + 1) / 2) + 1]
		if tri % 2 == 0 then --if the number is even use outer.
			p2 = outer[math_floor((tri + 1) / 2)]
		else
			p2 = inner[math_floor((tri + 1) / 2)]
		end

		table_insert(triarc, {p1,p2,p3})
	end

	-- Return a table of triangles to draw.
	return triarc
end

function surface.DrawArc(arc) -- Draw a premade arc.
	for k,v in ipairs(arc) do
		surface_DrawPoly(v)
	end
end