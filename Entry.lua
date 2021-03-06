
---
-- Editable text input widget.
--
-- In addition to handling text input, the widget has some basic editing
-- key bindings (some may not be available on all platforms):
--
-- * Left and right cursor keys move the insertion point one character to the
--   left and right, respectively.
-- * The Home and End keys move the insertion point to the beginning and end
--   of the text, respectively.
-- * Backspace and Delete remove the character directly to the left or right
--   of the insertion point, respectively.
-- * Enter or Return commits the text (calls the `committed` method).
--
-- **Extends:** `kloveui.Widget`
--
-- @classmod kloveui.Entry

local graphics = love.graphics

local Widget = require "kloveui.Widget"

local Entry = Widget:extend("kloveui.Entry")

local ibeam

Entry.canfocus = true

local utf8 = require "utf8"
local ustroffset = utf8.offset
local ustrlen = utf8.len

local function ustrsub(str, i, j)
	local len = ustrlen(str)
	i, j = i or 1, j or len
	if j < i or i > len then
		return ""
	elseif i == 0 then
		i = 1
	end
	i = ustroffset(str, i)
	j = ustroffset(str, j+1) or #str+1
	return str:sub(i, j-1)
end

---
-- Text of this entry box.
--
-- @tfield string text Default is the empty string.
Entry.text = ""

---
-- Custom font for this entry box.
--
-- @tfield love.graphics.Font font Default is nil.
Entry.font = nil

---
-- Index of insertion caret.
--
-- It refers to the space between characters, where 0 is just before the first
-- character, 1 is between the first and second characters, and so on.
--
-- Note that "characters" refers to groups of bytes representing characters in
-- the UTF-8 encoding. This is not the same unit Lua uses.
--
-- @tfield number index Default is 0.
Entry.index = 0

Entry.padding = 4

---
-- Convert from a pixel offset to an index.
--
-- @tparam number x Pixel offset from the left border of the widget.
-- @treturn number Index of the character at that position.
-- @see index
function Entry:postoindex(x)
	local pl = self:paddings()
	local text = self.text
	local len = ustrlen(text)
	x = x - pl
	if x < 0 then
		return 0
	elseif x >= self.w then
		return len
	end
	local font = self.font or graphics.getFont()
	for i = 1, len do
		local pfx = ustrsub(text, 1, i)
		local w = font:getWidth(pfx)
		if x<w then
			return i
		end
	end
	return len
end

---
-- Convert from an index to a pixel offset.
--
-- @tparam number index Index of the character.
-- @treturn number Pixel offset from the left border of the widget.
-- @see index
function Entry:indextopos(index)
	local pl = self:paddings()
	local font = self.font or graphics.getFont()
	return font:getWidth(ustrsub(self.text, 1, index))+pl
end

---
-- Called when the Enter key is pressed.
function Entry:committed()
end

function Entry:calcminsize()
	local font, text = self.font or graphics.getFont(), self.text
	local tw, th = font:getWidth(text), font:getHeight(text)
	local pl, pt, pr, pb = self:paddings()
	return tw+pl+pr, th+pt+pb
end

function Entry:mousepressed(x, y, b)
	if not self:inside(x, y) then return end
	self._pressed = b == 1
	return self:mousemoved(x, y, 0, 0)
end

function Entry:mousereleased(x, y, b)
	if self._pressed and b == 1 then
		self._pressed = false
	end
end

function Entry:mousemoved(x, y, dx, dy)
	if self._pressed then
		x = self:postoindex(x)
		self.index = x
	end
end

local oldcursor

function Entry:mouseenter()
	if love.mouse.isCursorSupported() then
		if not ibeam then
			ibeam = love.mouse.getSystemCursor("ibeam")
		end
		oldcursor = love.mouse.getCursor()
		if ibeam then
			love.mouse.setCursor(ibeam)
		end
	end
end

function Entry:mouseleave()
	if love.mouse.isCursorSupported() then
		love.mouse.setCursor(oldcursor)
	end
end

local hadtextinput

function Entry:focusgot()
	hadtextinput = love.keyboard.hasTextInput()
	love.keyboard.setTextInput(true)
end

function Entry:focuslost()
	love.keyboard.setTextInput(hadtextinput)
end

function Entry:keypressed(key)
	if key == "backspace" then
		if self.index < 1 then
			return
		end
		self.text = (ustrsub(self.text, 1, self.index-1)
				..ustrsub(self.text, self.index+1))
		self.index = self.index - 1
	elseif key == "delete" then
		if self.index > ustrlen(self.text) then
			return
		end
		self.text = (ustrsub(self.text, 1, self.index)
				..ustrsub(self.text, self.index+2))
	elseif key == "home" then
		self.index = 0
	elseif key == "end" then
		self.index = ustrlen(self.text)
	elseif key == "left" then
		if self.index <= 0 then
			return
		end
		self.index = self.index - 1
	elseif key == "right" then
		if self.index >= ustrlen(self.text) then
			return
		end
		self.index = self.index + 1
	elseif key == "return" or key == "kpenter" then
		self:committed()
	end
end

function Entry:textinput(text)
	local len = ustrlen(text)
	self.text = (ustrsub(self.text, 1, self.index)..text
			..ustrsub(self.text, self.index+1))
	self.index = self.index + len
end

function Entry:paintbg()
	Widget.paintbg(self)
	self:drawbevel(true)
end

function Entry:paintfg()
	local pl, pt, pr, pb = self:paddings()
	local w, h = self:size()
	self:drawtext(not self.enabled, self.text,
			0, 0, self.font,
			pl, pt, w-pl-pr, h-pt-pb)
	if self.hasfocus then
		local th = (self.font or graphics.getFont()):getHeight("Ay")
		local x = self:indextopos(self.index)
		graphics.line(x, pt-2, x, th+2)
	end
	Widget.paintfg(self)
end

return Entry
