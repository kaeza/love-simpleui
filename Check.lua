
---
-- Toggleable checkbox button.
--
-- Check buttons are toggled by clicking.
--
-- **Extends:** `kloveui.Button`
--
-- **Direct subclasses:**
--
-- * `kloveui.Option`
--
-- @classmod kloveui.Check

local graphics = love.graphics

local Widget = require "kloveui.Widget"
local Button = require "kloveui.Button"

local Check = Button:extend("kloveui.Check")

---
-- Current value of the checkmark.
--
-- @tfield boolean value Default is false.
Check.value = false

Check.texthalign = 0

function Check:calcminsize()
	local font, text = self.font or graphics.getFont(), self.text
	local tw, th = font:getWidth(text), font:getHeight(text)
	local pl, pt, pr, pb = self:paddings()
	return th+2+tw+pl+pr, th+pt+pb
end

---
-- Called to paint the "check" part.
--
-- @tparam boolean value True if checked, false if unchecked.
-- @tparam number x X position.
-- @tparam number y Y position.
-- @tparam number size Size of the checkbox.
function Check:paintcheck(value, x, y, size)
	graphics.rectangle("line", x, y, size, size)
	if value then
		graphics.rectangle("fill", x+3, y+3, size-6, size-6)
	end
end

function Check:paintbg()
	Widget.paintbg(self)
end

function Check:paintfg()
	local font, text = self.font or graphics.getFont(), self.text
	local pl, pt, pr, pb = self:paddings()
	local th = font:getHeight(text)
	local p = self.pressed and 1 or 0
	self:drawtext(not self.enabled, self.text,
			self.texthalign, self.textvalign, self.font,
			p+pl+th+2, p+pt, self.w-pl-pr-th+2, self.h-pt-pb)
	self:paintcheck(self.value, pl, pt, th, th)
	Widget.paintfg(self)
end

function Check:activated()
	self.value = not self.value
end

return Check
