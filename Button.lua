
---
-- Clickable button.
--
-- **Extends:** `kloveui.Widget`
--
-- **Direct subclasses:**
--
-- * `kloveui.Check`
--
-- @classmod kloveui.Button

local graphics = love.graphics

local Widget = require "kloveui.Widget"

local Button = Widget:extend("kloveui.Button")

---
-- Text label for the button.
--
-- @tfield string text Default is the empty string.
Button.text = ""

---
-- Custom font for the button.
--
-- @tfield love.graphics.Font font Default is nil.
Button.font = nil

---
-- Horizontal alignment for the text.
--
-- @tfield number texthalign Default is 0.5.
-- @see kloveui.Widget:drawtext
Button.texthalign = .5

---
-- Vertical alignment for the text.
--
-- @tfield number textvalign Default is 0.5.
-- @see kloveui.Widget:drawtext
Button.textvalign = .5

---
-- Whether the button is currently pressed.
--
-- @todo This should be private.
-- @tfield boolean pressed
Button.pressed = false

Button.padding = 4

---
-- Called when the button is clicked.
function Button:activated()
end

function Button:calcminsize()
	local font, text = self.font or graphics.getFont(), self.text
	local tw, th = font:getWidth(text), font:getHeight(text)
	local pl, pt, pr, pb = self:paddings()
	return tw+pl+pr, th+pt+pb
end

function Button:mousepressed(x, y, b)
	if self:inside(x, y) then
		self.pressed = b == 1
		self.hasmouse = self.pressed
	end
end

function Button:mousereleased(x, y, b)
	if self.hasmouse and b == 1 and self:inside(x, y) then
		self:activated()
	end
	self.pressed = false
	self.hasmouse = false
end

function Button:mousemoved(x, y, dx, dy)
	self.pressed = self.hasmouse and self:inside(x, y)
end

function Button:paintbg()
	Widget.paintbg(self)
	self:drawbevel(self.pressed)
end

function Button:paintfg()
	local pl, pt, pr, pb = self:paddings()
	local p = self.pressed and 1 or 0
	self:drawtext(not self.enabled, self.text,
			self.texthalign, self.textvalign, self.font,
			pl+p, pt+p, self.w-pl-pr, self.h-pt-pb)
	Widget.paintfg(self)
end

return Button
