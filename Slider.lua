
---
-- Widget to select from a range of values.
--
-- **Extends:** `simpleui.Widget`
--
-- @classmod simpleui.Slider

local gfx = love.graphics
local min, max, floor = math.min, math.max, math.floor

local Widget = require "simpleui.Widget"

local Slider = Widget:extend("Slider")

---
-- Current value for the slider.
--
-- Lies in the range 0-1 (inclusive).
--
-- @tfield number value Default is 0.
Slider.value = 0

---
-- Value increment.
--
-- If a number, the value snaps to the nearest multiple of that value;
-- if nil, the value resolution depends on the widget's size.
--
-- @tfield nil|number increment Default is nil.
Slider.increment = nil

---
-- Anchor border.
--
-- If it is `"l"`, the value increments left to right.
-- If it is `"r"`, the value increments right to left.
-- If it is `"t"`, the value increments top to bottom.
-- If it is `"b"`, the value increments bottom to top.
--
-- @tfield string anchor Default is "l".
Slider.anchor = "l"

---
-- Color for the handle while pressed.
--
-- @tfield simpleui.Color handlecolorpressed Default is (192, 192, 192).
Slider.handlecolorpressed = ({ 192, 192, 192 })

---
-- Set the slider's value.
--
-- This method calls `valuechanged` if the value is different.
--
-- @tparam number v New value. Clamped to the range 0-1.
-- @tparam ?boolean force Set new value even if unchanged. Default is false.
-- @treturn number Old value.
function Slider:setvalue(v, force)
	local old = self.value
	v = max(0, min(1, v))
	if force or v ~= self.value then
		self.value = v
		self:valuechanged()
	end
	return old
end

---
-- Called to paint the handle.
--
-- The handle is part of the "foreground".
--
-- @tparam number x X position of the center of the handle.
-- @tparam number y Y position of the center of the handle.
-- @tparam boolean vert True if this is a vertical bar, false otherwise.
-- @tparam boolean pressed True if the handle is currently pressed,
--  false otherwise.
-- @see simpleui.Widget:paintfg
function Slider:painthandle(x, y, vert, pressed)
	local size = (vert and self.w or self.h)/4
	local fg = (self.enabled
			and (pressed and self.handlecolorpressed or self.fgcolor)
			or self.fgcolordisabled)
	local bc = self.bordercolor
	gfx.push()
	gfx.translate(x, y)
	if vert then
		gfx.rotate(math.pi/2)
	end
	gfx.setColor(fg)
	--                 | P1        | P2              | P3
	gfx.polygon("fill", 0, -size, -size, -size*2, size, -size*2)
	gfx.polygon("fill", 0,  size, -size,  size*2, size,  size*2)
	gfx.line(0, -size, 0, size)
	gfx.setColor(bc)
	gfx.polygon("line", 0, -size, -size, -size*2, size, -size*2)
	gfx.polygon("line", 0,  size, -size,  size*2, size,  size*2)
	gfx.pop()
end

---
-- Called to paint the bar.
--
-- The bar is part of the "background".
--
-- @tparam number x X position of the center of the handle.
-- @see simpleui.Widget:paintbg
function Slider:paintbar()
	gfx.setColor(self.bgcolor)
	gfx.rectangle("fill", 0, 0, self.w, self.h)
end

---
-- Called when the value of the bar changes.
--
-- @see value
function Slider:valuechanged()
end

function Slider:calcminsize()
	if self.anchor == "t" or self.anchor == "b" then
		return 16, 32
	else
		return 32, 16
	end
end

function Slider:mousepressed(x, _, b)
	if b == self.LMB then
		self._pressed = true
		self:mousemoved(x)
	end
end

function Slider:mousereleased(_, _, b)
	if b == self.LMB then
		self._pressed = nil
	end
end

function Slider:mousemoved(x, y)
	if self._pressed then
		local anchor = self.anchor
		local v
		if anchor == "t" then
			v = y/self.h
		elseif anchor == "b" then
			v = 1-y/self.h
		elseif anchor == "r" then
			v = 1-x/self.w
		else
			v = x/self.w
		end
		if self.increment then
			v = floor(v/self.increment+.5)*self.increment
		end
		self:setvalue(v)
	end
end

function Slider:wheelmoved(_, y)
	local v = self.value + (self.increment or .1)*(-y)
	self:setvalue(v)
end

function Slider:paintfg()
	local anchor = self.anchor
	local vert = anchor == "t" or anchor == "b"
	local invert = anchor == "r" or anchor == "b"
	local x = vert and self.w/2 or self.w*self.value
	local y = vert and self.h*self.value or self.h/2
	if invert then
		x, y = self.w-x, self.h-y
	end
	self:painthandle(x, y, vert, self._pressed)
	Widget.paintfg(self)
end

function Slider:paintbg()
	Widget.paintbg(self)
	self:paintbar()
	gfx.setColor(self.bordercolor)
	gfx.rectangle("line", 0, 0, self.w, self.h)
end

return Slider