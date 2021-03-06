
---
-- Base class for all widgets.
--
-- **Extends:** `klass`
--
-- **Direct subclasses:**
--
-- * `kloveui.Box`
-- * `kloveui.Button`
-- * `kloveui.Entry`
-- * `kloveui.Image`
-- * `kloveui.Label`
-- * `kloveui.Slider`
--
-- @classmod kloveui.Widget

local graphics = love.graphics

local klass = require "klass"

local Widget = klass:extend("kloveui.Widget")

---
-- ID of this widget.
--
-- @tfield any id Default is nil.
-- @see kloveui.lookup
Widget.id = nil

---
-- Widget's horizontal position relative to its parent's origin.
--
-- @tfield number x Default is 0.
-- @see pos
Widget.x = 0

---
-- Widget's vertical position relative to its parent's origin.
--
-- @tfield number y Default is 0.
-- @see pos
Widget.y = 0

---
-- Widget's current width.
--
-- @tfield number w Default is 1.
-- @see size
Widget.w = 1

---
-- Widget's current height.
--
-- @tfield number h Default is 1.
-- @see size
Widget.h = 1

---
-- Widget's minimum width.
--
-- @tfield ?number minw Default is nil.
-- @see minsize
Widget.minw = nil

---
-- Widget's minimum height.
--
-- @tfield ?number minh Default is nil.
-- @see minsize
Widget.minh = nil

---
-- Widget's maximum width.
--
-- @tfield ?number maxw Default is nil.
-- @see maxsize
Widget.maxw = nil

---
-- Widget's maximum height.
--
-- @tfield ?number maxh Default is nil.
-- @see maxsize
Widget.maxh = nil

---
-- Whether or not the widget is enabled.
--
-- Disabled widgets don't receive input events.
--
-- @tfield boolean enabled Default is true.
Widget.enabled = true

---
-- Color for foreground graphics.
--
-- @tfield kloveui.Color fgcolor Default is (.95, .95, .95).
Widget.fgcolor = ({ .95, .95, .95 })

---
-- Color for foreground graphics when disabled.
--
-- @tfield kloveui.Color fgcolordisabled Default is (.75, .75, .75).
-- @see enabled
Widget.fgcolordisabled = ({ .75, .75, .75 })

---
-- Color for background graphics.
--
-- @tfield kloveui.Color bgcolor Default is (.25, .25, .25).
Widget.bgcolor = ({ .25, .25, .25 })

---
-- Color for background graphics when raised.
--
-- @tfield kloveui.Color bgcolorraised Default is (.5, .5, .5).
-- @see drawbevel
Widget.bgcolorraised = ({ .5, .5, .5 })

---
-- Color for background graphics when sunken.
--
-- @tfield kloveui.Color bgcolorsunken Default is (.125, .125, .125).
-- @see drawbevel
Widget.bgcolorsunken = ({ .125, .125, .125 })

---
-- Color for the border.
--
-- @tfield kloveui.Color bordercolor Default is (0, 0, 0).
Widget.bordercolor = ({ 0, 0, 0 })

---
-- Whether the widget should be expanded as much as possible.
--
-- May be used by layout widgets.
--
-- @tfield boolean expand Default is false.
Widget.expand = false

---
-- Margin around the widget.
--
-- May be used by layout widgets.
--
-- @tfield kloveui.Border|number margin Default is 0.
Widget.margin = 0

---
-- Padding around the widget's content.
--
-- @tfield kloveui.Border|number padding Default is 0.
Widget.padding = 0

---
-- Whether or not the widget can grab the input focus.
--
-- @tfield boolean canfocus Default is false.
-- @see kloveui.setfocus
Widget.canfocus = false

---
-- Whether or not the widget currently has the input focus.
--
-- @tfield boolean hasfocus Default is false.
-- @see kloveui.setfocus
Widget.hasfocus = false

---
-- Table to hold weak references.
--
-- The base `Widget` class only uses the `parent` field to hold a reference to
-- the widget's parent. Subclasses may use other fields.
--
-- **NOTE: This field should not be overridden. It is documented here so
-- subclasses don't introduce name clashes.**
--
-- @tfield table weakrefs Initialized to new table on instantiation.
Widget.weakrefs = nil

---
-- Whether or not to draw debugging information.
--
-- @tfield boolean __debug Default is nil.
Widget.__debug = nil

---
-- Constructor.
--
-- @tparam table params Field overrides. Non-nil fields are copied to the
--  new instance. Where it makes any difference, only references are copied,
--  not values.
function Widget:init(params)
	self.weakrefs = setmetatable({ }, { __mode="kv" })
	for _, v in ipairs(params) do
		v.weakrefs.parent = self
	end
	for k, v in pairs(params) do
		self[k] = v
	end
end

local function repr(x)
	return type(x) == "string" and ("%q"):format(x) or tostring(x)
end

---
-- Get a string representation of this widget.
--
-- @treturn string String in the format
--  `<CLASSNAME: x=X, y=Y, w=W, h=H, id=ID>`.
--  The `id=ID` part is omitted if `id` is nil.
function Widget:__tostring()
	return ("<%s: x=%s, y=%s, w=%s, h=%s%s>"):format(self.__name,
			self.x, self.y, self.w, self.h,
			self.id==nil and "" or ", id="..repr(self.id))
end

---
-- Add a child to this widget.
--
-- @tparam kloveui.Widget child Child widget.
-- @tparam ?number pos Position at which to insert the child in the list.
--  Default is to append to the end of the list.
-- @treturn Widget The child.
function Widget:addchild(child, pos)
	child.weakrefs.parent = self
	table.insert(self, pos or #self+1, child)
	return child
end

---
-- Remove a child from this widget.
--
-- @tparam kloveui.Widget|number child Child widget, or list index.
-- @treturn kloveui.Widget|nil The removed widget, or nil if the specified
--  widget is not a child of this one or the list index is out of bounds.
function Widget:removechild(child)
	if type(child) == "number" then
		local  r = table.remove(self, child)
		return r
	else
		for c, i in self:children() do
			if rawequal(c, child) then
				child.weakrefs.parent = nil
				local r = table.remove(self, i)
				return r
			end
		end
	end
end

---
-- Called to lay out children.
--
-- May be used by layout widgets.
--
-- The default implementation does nothing.
function Widget:layout()
end

---
-- Look up a sub-widget by ID.
--
-- The search is performed depth-first. If a widget has the same ID as a
-- descendant, its descendant takes preference. In the case of siblings with
-- the same ID, the first sibling in its parent's list takes preference.
--
-- @tparam any id ID to look up.
-- @treturn kloveui.Widget|nil The widget if found, nil otherwise.
-- @see id
function Widget:lookup(id)
	for child in self:children() do
		local found = child:lookup(id)
		if found then
			return found
		end
	end
	if id == self.id then
		return self
	end
end

---
-- Iterate over this widget's children.
--
-- Returns an iterator function so that the construction:
--
--     for child, index in widget:children() do
--         -- ...
--     end
--
-- will iterate over all children of this widget.
--
-- @tparam ?boolean reversed If true, iterate in reversed order.
-- @treturn function Iterator function.
function Widget:children(reversed)
	local len = #self
	local index = reversed and len or 1
	local step = reversed and -1 or 1
	return function()
		local c, i = self[index], index
		index = index + step
		return c, i
	end
end

---
-- Tests whether there's a widget at some coordinates.
--
-- The test is performed depth-first. Descendants take preference. In the case
-- of siblings, the last sibling in its parent's list takes preference.
--
-- NOTE: The coordinates are relative to this widget's parent's origin!
--
-- @tparam number x X position.
-- @tparam number y Y position.
-- @treturn Widget|nil widget The widget found, nil otherwise. Note that
--  disabled widgets are not taken into account.
-- @treturn number|nil rx X coordinate relative to the child found, or nil.
-- @treturn number|nil ry Y coordinate relative to the child found, or nil.
-- @see enabled
-- @see inside
function Widget:hittest(x, y)
	if not self.enabled then
		return nil
	end
	x, y = x-self.x, y-self.y
	if not self:inside(x, y) then
		return
	end
	for child in self:children(true) do
		local found, rx, ry = child:hittest(x, y)
		if found then
			return found, rx, ry
		end
	end
	return self, x, y
end

---
-- Tests whether a point lies within this widget.
--
-- Coordinates are relative to this widget's origin.
--
-- @tparam number x X coordinate.
-- @tparam number y Y coordinate.
-- @treturn boolean True if the point is inside, false otherwise.
function Widget:inside(x, y)
	return x>=0 and y>=0 and x<self.w and y<self.h
end

---
-- Get the absolute coordinates of this widget.
--
-- @treturn number x X coordinate.
-- @treturn number y Y coordinate.
function Widget:abspos()
	local x, y = 0, 0
	local w = self
	while w do
		x, y = x+w.x, y+w.y
		w = w.weakrefs.parent
	end
	return x, y
end

---
-- Get the minimum size for this widget.
--
-- The minimum size is generally the minimum allowed size at which all content
-- is visible.
--
-- This method checks if `minw` and `minh` are set. If any of those are not
-- set, calls `calcminsize` to fill-in the missing dimension(s).
--
-- @treturn number w Width.
-- @treturn number h Height.
-- @see size
-- @see maxsize
function Widget:minsize()
	local w, h = self.minw, self.minh
	if not (w and h) then
		local mw, mh = self:calcminsize()
		w, h = w or mw, h or mh
	end
	return w, h
end

---
-- Calculate the minimum size for this widget.
--
-- The default implementation returns 1 for both dimensions. Subclasses should
-- override this method to give a more meaningful value.
--
-- @treturn number w Width.
-- @treturn number h Height.
-- @see size
-- @see minsize
function Widget:calcminsize()
	return 1, 1
end

---
-- Get the maximum size for this widget.
--
-- This method checks if `maxw` and `maxh` are set. If any of those are not
-- set, calls `calcmaxsize` to fill-in the missing dimension(s).
--
-- @treturn number w Width.
-- @treturn number h Height.
-- @see size
-- @see minsize
function Widget:maxsize()
	local w, h = self.maxw, self.maxh
	if not (w and h) then
		local mw, mh = self:calcmaxsize()
		w, h = w or mw, h or mh
	end
	return w, h
end

---
-- Calculate the maximum size for this widget.
--
-- The default implementation returns infinite for both dimensions. It is not
-- usually needed to override this method, but it's provided in case it's
-- needed.
--
-- @treturn number w Width.
-- @treturn number h Height.
-- @see size
-- @see maxsize
function Widget:calcmaxsize()
	local w, h
	if self.weakrefs.parent then
		w, h = self.weakrefs.parent:maxsize()
	else
		w, h = love.window.getMode()
	end
	return w-self.x, h-self.y
end

---
-- Get the margins around the widget.
--
-- May be used by layout widgets.
--
-- @treturn number Left margin.
-- @treturn number Top margin.
-- @treturn number Right margin.
-- @treturn number Bottom margin.
-- @see margin
function Widget:margins()
	local t = self.margin
	if type(t) == "number" then
		return t, t, t, t
	else
		return t.l or 0, t.t or 0, t.r or 0, t.b or 0
	end
end

---
-- Get the padding around the widget.
--
-- @treturn number Left padding.
-- @treturn number Top padding.
-- @treturn number Right padding.
-- @treturn number Bottom padding.
-- @see padding
function Widget:paddings()
	local t = self.padding
	if type(t) == "number" then
		return t, t, t, t
	else
		return t.l or 0, t.t or 0, t.r or 0, t.b or 0
	end
end

---
-- Get and/or change the widget's position.
--
-- Unspecified parameters are unchanged.
--
-- @tparam ?number x New X coordinate.
-- @tparam ?number y New Y coordinate.
-- @treturn number x X coordinate, after possible change.
-- @treturn number y Y coordinate, after possible change.
function Widget:pos(x, y)
	local mod
	if x ~= nil then mod, self.x = true, x end
	if y ~= nil then mod, self.y = true, y end
	if mod then
		self:layout()
	end
	return self.x, self.y
end

---
-- Get and/or change the widget's size.
--
-- Unspecified parameters are unchanged.
--
-- The widget's size is clamped to fall within its minimum and maximum sizes.
--
-- @tparam ?number w New width.
-- @tparam ?number h New height.
-- @treturn number w Width, after possible change.
-- @treturn number h Height, after possible change.
-- @see minsize
-- @see maxsize
function Widget:size(w, h)
	local mod
	local minw, minh = self:minsize()
	local maxw, maxh = self:maxsize()
	if w ~= nil then
		mod, self.w = true, math.max(minw, math.min(maxw, w))
	end
	if h ~= nil then
		mod, self.h = true, math.max(minh, math.min(maxh, h))
	end
	if mod then
		self:layout()
	end
	return self.w, self.h
end

---
-- Get and/or change the widget's position and size.
--
-- Unspecified parameters are unchanged.
--
-- The widget's size is clamped to fall within its minimum and maximum sizes.
--
-- @tparam ?number x New X coordinate.
-- @tparam ?number y New Y coordinate.
-- @tparam ?number w New width.
-- @tparam ?number h New height.
-- @treturn number x X coordinate, after possible change.
-- @treturn number y Y coordinate, after possible change.
-- @treturn number w Width, after possible change.
-- @treturn number h Height, after possible change.
function Widget:rect(x, y, w, h)
	local mod
	if x ~= nil then mod, self.x = true, x end
	if y ~= nil then mod, self.y = true, y end
	local minw, minh = self:minsize()
	local maxw, maxh = self:maxsize()
	if w ~= nil then
		mod, self.w = true, math.max(minw, math.min(maxw, w))
	end
	if h ~= nil then
		mod, self.h = true, math.max(minh, math.min(maxh, h))
	end
	if mod then
		self:layout()
	end
	return self.x, self.y, self.w, self.h
end

---
-- Called by the system to draw the widget.
--
-- Do not override this method. Override `paintfg` and/or `paintbg` instead.
function Widget:draw()
	graphics.push()
	graphics.translate(self.x, self.y)
	self:paintbg()
	for child in self:children() do
		child:draw()
	end
	self:paintfg()
	graphics.pop()
end

---
-- Draws the widget's foreground elements.
--
-- While this method is active, graphics coordinates are relative to this
-- widget's origin.
function Widget:paintfg()
	if self.__debug then
		graphics.setColor(1, 1, 0, .75)
		graphics.rectangle("line", 0, 0, self:size())
		graphics.print(tostring(self))
	end
end

---
-- Draws the widget's background elements.
--
-- While this method is active, graphics coordinates are relative to this
-- widget's origin.
function Widget:paintbg()
end

---
-- Utility method to draw bevels.
--
-- @tparam boolean sunken If true, draw a "sunken" rectangle. If false, draw
--  a "raised" rectangle.
-- @tparam ?number x X coordinate. Defaults to 0.
-- @tparam ?number y Y coordinate. Defaults to 0.
-- @tparam ?number w Width. Defaults to this widget's width.
-- @tparam ?number h Height. Defaults to this widget's height.
-- @see bgcolorraised
-- @see bgcolorsunken
-- @see bordercolor
function Widget:drawbevel(sunken, x, y, w, h)
	x, y, w, h = x or 0, y or 0, w or self.w, h or self.h
	graphics.setColor(sunken and self.bgcolorsunken or self.bgcolorraised)
	graphics.rectangle("fill", x, y, w, h)
	graphics.setColor(self.bordercolor)
	graphics.rectangle("line", x, y, w, h)
end

---
-- Utility method to draw textual content.
--
-- @tparam boolean disabled If true, draw with the disabled color. If false,
--  draw with the normal color.
-- @tparam string text Text to draw.
-- @tparam number halign Horizontal alignment within the rectangle. 0 is
--  left-aligned, 1 is right-aligned, 0.5 is centered.
-- @tparam number valign Vertical alignment within the rectangle. 0 is
--  top-aligned, 1 is bottom-aligned, 0.5 is centered.
-- @tparam ?love.graphics.Font font Font to use. Default is the font currently
--  selected with `love.graphics.setFont`.
-- @tparam ?number x X coordinate. Defaults to 0.
-- @tparam ?number y Y coordinate. Defaults to 0.
-- @tparam ?number w Width. Defaults to this widget's width.
-- @tparam ?number h Height. Defaults to this widget's height.
-- @see fgcolor
-- @see fgcolordisabled
function Widget:drawtext(disabled, text, halign, valign, font, x, y, w, h)
	x, y, w, h = x or 0, y or 0, w or self.w, h or self.h
	graphics.setColor(disabled and self.fgcolordisabled or self.fgcolor)
	local oldfont = graphics.getFont()
	font = font or oldfont
	local tw, th = font:getWidth(text), font:getHeight(text)
	graphics.setFont(font)
	graphics.print(text,
			math.floor(x+((w-tw)*halign)),
			math.floor(y+((h-th)*valign)))
	graphics.setFont(oldfont)
end

---
-- Called to update this widget's logic.
--
-- @tparam number dtime
function Widget:update(dtime)
	for child in self:children() do
		child:update(dtime)
	end
end

---
-- Set this widget as the input focus.
--
-- Equivalent to `kloveui.setfocus(self)`.
--
-- @treturn kloveui.Widget|nil oldfocus The old input focus, or nil if no
--  widget had the input focus.
-- @see kloveui.setfocus
function Widget:setfocus()
	return require("kloveui").setfocus(self)
end

---
-- Run this widget.
--
-- Equivalent to `kloveui.run(self, ...)`.
--
-- @tparam ?number scale GUI scaling factor. Default is 1.
-- @treturn ?number App exit status (return value of `love.run`).
-- @see kloveui.run
function Widget:run(scale)
	return require("kloveui").run(self, scale)
end

---
-- Run this widget.
--
-- Equivalent to `kloveui.runsub(self, ...)`.
--
-- @tparam ?number scale GUI scaling factor. Default is 1.
-- @treturn ?number App exit status (return value of `love.run`).
-- @see kloveui.runsub
function Widget:runsub(scale)
	return require("kloveui").runsub(self, scale)
end

---
-- Called by the system when this widget receives the input focus.
function Widget:focusgot()
end

---
-- Called by the system when this widget loses the input focus.
function Widget:focuslost()
end

---
-- Called by the system to handle mouse input.
--
-- @tparam number x Mouse X.
-- @tparam number y Mouse Y.
-- @tparam number b Mouse button.
-- @tparam boolean istouch Whether the event was generated by a touch screen.
function Widget:mousepressed(x, y, b, istouch)
end

---
-- Called by the system to handle mouse input.
--
-- @tparam number x Mouse X.
-- @tparam number y Mouse Y.
-- @tparam number b Mouse button.
-- @tparam boolean istouch Whether the event was generated by a touch screen.
function Widget:mousereleased(x, y, b, istouch)
end

---
-- Called by the system to handle mouse input.
--
-- @tparam number x Mouse X.
-- @tparam number y Mouse Y.
-- @tparam number dx Mouse X difference since last call.
-- @tparam number dy Mouse Y difference since last call.
-- @tparam boolean istouch Whether the event was generated by a touch screen.
function Widget:mousemoved(x, y, dx, dy, istouch)
end

---
-- Called by the system when the mouse enters this widget.
--
-- @todo Not implemented yet.
function Widget:mouseenter()
end

---
-- Called by the system when the mouse leaves this widget.
--
-- @todo Not implemented yet.
function Widget:mouseleave()
end

---
-- Called by the system to handle mouse input.
--
-- @tparam number dx Wheel X difference.
-- @tparam number dy Wheel Y difference.
function Widget:wheelmoved(dx, dy)
end

---
-- Called by the system to handle keyboard input.
--
-- @tparam love.keyboard.KeyConstant key Key name.
-- @tparam love.keyboard.Scancode scan Key scan code.
-- @tparam boolean isrep Whether this event was generated due to key repeat.
-- @tparam kloveui.ShiftState shift Shift state.
function Widget:keypressed(key, scan, isrep, shift)
end

---
-- Called by the system to handle keyboard input.
--
-- @tparam love.keyboard.KeyConstant key Key name.
-- @tparam love.keyboard.Scancode scan Key scan code.
-- @tparam kloveui.ShiftState shift Shift state.
function Widget:keyreleased(key, scan, shift)
end

---
-- Called by the system to handle keyboard input.
--
-- @tparam string text Text entered by the user.
function Widget:textinput(text)
end

return Widget
