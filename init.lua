
---
-- Core functions.
--
-- This module also exports all widgets itself so users don't need to import
-- each sub-module separately.
--
-- @module kloveui

local kloveui = { }

local event = love.event
local timer = love.timer
local graphics = love.graphics
local keyboard = love.keyboard

kloveui.Box = require "kloveui.Box"
kloveui.Button = require "kloveui.Button"
kloveui.Check = require "kloveui.Check"
kloveui.Entry = require "kloveui.Entry"
kloveui.Image = require "kloveui.Image"
kloveui.Label = require "kloveui.Label"
kloveui.Option = require "kloveui.Option"
kloveui.Slider = require "kloveui.Slider"
kloveui.Widget = require "kloveui.Widget"

---
-- Table used to represent a color.
--
-- All components are numbers in the range 0 to 1 (inclusive).
--
-- @table Color
-- @tfield number 1 Red component.
-- @tfield number 2 Green component.
-- @tfield number 3 Blue component.
-- @tfield ?number 4 Alpha (transparency) component. 0 means fully
--  transparent, and 1 means fully opaque. Values in-between mean
--  partial transparency. If nil, defaults to 1.

---
-- Table used to represent border sizes.
--
-- Fields not specified default to 0.
--
-- @table Border
-- @tfield ?number l Left.
-- @tfield ?number t Top.
-- @tfield ?number r Right.
-- @tfield ?number b Bottom.

---
-- Enum representing shift state.
--
-- @table ShiftState
-- @field c Control key is down.
-- @field a Alt key is down.
-- @field s Shift key is down.
-- @field ca Control and Alt keys are down.
-- @field cs Control and Shift keys are down.
-- @field as Alt and Shift keys are down.
-- @field cas Control, Alt and Shift keys are down.

local rootwidget
local hoverwidget, mousewidget, mousewidgetx, mousewidgety
local focuswidget
local guiscale

local ctrl, alt, shift

---
-- Look up a widget by ID.
--
-- This is equivalent to calling `lookup` method on the root widget.
-- See the method's documentation for implementation details.
--
-- @tparam any id ID to look up.
-- @treturn kloveui.Widget|nil The widget if found, nil otherwise.
-- @see kloveui.Widget.id
-- @see kloveui.Widget:lookup
function kloveui.lookup(id)
	return rootwidget:lookup(id)
end

---
-- Get shift state.
--
-- @treturn ShiftState Shift state.
function kloveui.getshiftstate()
	return table.concat({
		ctrl  and "c" or "",
		alt   and "a" or "",
		shift and "s" or "",
	})
end

---
-- Called by the system to draw the GUI.
--
-- Set as same-named `love` callback by `run`.
function kloveui.draw()
	graphics.push()
	graphics.scale(guiscale, guiscale)
	rootwidget:draw()
	graphics.pop()
end

---
-- Called by the system to update the GUI logic.
--
-- Set as same-named `love` callback by `run`.
--
-- @tparam number dtime Time since last call, in seconds.
function kloveui.update(dtime)
	rootwidget:update(dtime)
end

local function getmouse(x, y)
	local wid, rx, ry
	if mousewidget then
		wid, rx, ry = mousewidget, x-mousewidgetx, y-mousewidgety
	else
		wid, rx, ry = rootwidget:hittest(x, y)
	end
	return wid, rx, ry
end

---
-- Called by the system to handle mouse input.
--
-- Set as same-named `love` callback by `run`.
--
-- @tparam number x Mouse X.
-- @tparam number y Mouse Y.
-- @tparam number b Mouse button.
-- @tparam boolean istouch Whether the event was generated by a touch screen.
function kloveui.mousepressed(x, y, b, istouch)
	x, y = x/guiscale, y/guiscale
	local wid, rx, ry = getmouse(x, y)
	if wid then
		if wid.canfocus then
			kloveui.setfocus(wid)
		end
		mousewidget, mousewidgetx, mousewidgety = wid, wid:abspos()
		wid:mousepressed(rx, ry, b, istouch)
	end
end

---
-- Called by the system to handle mouse input.
--
-- Set as same-named `love` callback by `run`.
--
-- @tparam number x Mouse X.
-- @tparam number y Mouse Y.
-- @tparam number b Mouse button.
-- @tparam boolean istouch Whether the event was generated by a touch screen.
function kloveui.mousereleased(x, y, b, istouch)
	x, y = x/guiscale, y/guiscale
	local wid, rx, ry = getmouse(x, y)
	if wid then
		wid:mousereleased(rx, ry, b, istouch)
		mousewidget, mousewidgetx, mousewidgety = nil, nil, nil
	end
end

---
-- Called by the system to handle mouse input.
--
-- Set as same-named `love` callback by `run`.
--
-- @tparam number x Mouse X.
-- @tparam number y Mouse Y.
-- @tparam number dx Mouse X difference since last call.
-- @tparam number dy Mouse Y difference since last call.
-- @tparam boolean istouch Whether the event was generated by a touch screen.
function kloveui.mousemoved(x, y, dx, dy, istouch)
	x, y = x/guiscale, y/guiscale
	if mousewidget then
		mousewidget:mousemoved(x-mousewidgetx, y-mousewidgety,
				dx, dy, istouch)
	else
		local wid, rx, ry = getmouse(x, y)
		if wid ~= hoverwidget then
			if hoverwidget then
				hoverwidget:mouseleave()
			end
			hoverwidget = wid
			if wid then
				wid:mouseenter()
			end
		end
		if wid then
			wid:mousemoved(rx, ry, dx, dy, istouch)
		end
	end
end

---
-- Called by the system to handle mouse input.
--
-- Set as same-named `love` callback by `run`.
--
-- @tparam number dx Wheel X difference.
-- @tparam number dy Wheel Y difference.
function kloveui.wheelmoved(dx, dy)
	if mousewidget then
		mousewidget:wheelmoved(dx, dy)
	else
		local x, y = love.mouse.getPosition()
		x, y = x/guiscale, y/guiscale
		local wid = getmouse(x, y)
		if wid then
			wid:wheelmoved(dx, dy)
		end
	end
end

---
-- Called by the system to handle window resizes.
--
-- Set as same-named `love` callback by `run`.
--
-- @tparam number w
-- @tparam number h
function kloveui.resize(w, h)
	w, h = w/guiscale, h/guiscale
	rootwidget:rect(0, 0, w, h)
end

---
-- Called by the system to handle keyboard input.
--
-- Set as same-named `love` callback by `run`.
--
-- @tparam love.keyboard.KeyConstant key Key name.
-- @tparam love.keyboard.Scancode scan Key scan code.
-- @tparam boolean isrep Whether this event was generated due to key repeat.
function kloveui.keypressed(key, scan, isrep)
	if key == "lshift" or key == "rshift" then
		shift = true
	elseif key == "lalt" or key == "ralt" then
		alt = true
	elseif key == "lctrl" or key == "rctrl" then
		ctrl = true
	end
	if focuswidget then
		focuswidget:keypressed(key, scan, isrep, kloveui.getshiftstate())
	end
end

---
-- Called by the system to handle keyboard input.
--
-- Set as same-named `love` callback by `run`.
--
-- @tparam love.keyboard.KeyConstant key Key name.
-- @tparam love.keyboard.Scancode scan Key scan code.
function kloveui.keyreleased(key, scan)
	if key == "lshift" or key == "rshift" then
		shift = nil
	elseif key == "lalt" or key == "ralt" then
		alt = nil
	elseif key == "lctrl" or key == "rctrl" then
		ctrl = nil
	end
	if focuswidget then
		focuswidget:keyreleased(key, scan, kloveui.getshiftstate())
	end
end

---
-- Called by the system to handle keyboard input.
--
-- Set as same-named `love` callback by `run`.
--
-- @tparam string text Text entered by the user.
function kloveui.textinput(text)
	if focuswidget then
		focuswidget:textinput(text)
	end
end

---
-- Set the input focus.
--
-- @tparam kloveui.Widget wid Widget that will receive the input focus.
-- @treturn kloveui.Widget|nil The old input focus, or nil if no widget had
--  the input focus.
function kloveui.setfocus(wid)
	local old = focuswidget
	if old then
		old.hasfocus = false
		old:focuslost()
	end
	focuswidget = wid
	if wid then
		wid.hasfocus = true
		wid:focusgot()
	end
	return old
end

---
-- Get the widget that has the input focus.
--
-- @treturn kloveui.Widget|nil focus A widget, or nil if no widget has the
--  input focus.
function kloveui.getfocus()
	return focuswidget
end

local handlers = {
	"draw",
	"update",
	"mousepressed",
	"mousereleased",
	"mousemoved",
	"wheelmoved",
	"keypressed",
	"keyreleased",
	"textinput",
	"resize",
}

for i, k in ipairs(handlers) do
	handlers[i] = nil
	handlers[k] = function(...)
		return kloveui[k](...)
	end
end

local function mainloop()
	while true do
		event.pump()
		for name, a, b, c, d, e, f in event.poll() do
			if name == "quit" then
				if not love.quit or not love.quit() then
					return a or 0
				end
			end
			local func = handlers[name] or love.handlers[name]
			if func then
				func(a, b, c, d, e, f)
			end
		end
		local dt = timer.step()
		kloveui.update(dt)
		graphics.origin()
		graphics.clear(graphics.getBackgroundColor())
		kloveui.draw()
		graphics.present()
		timer.sleep(0.001)
	end
end

---
-- Run the GUI.
--
-- Sets the specified widget as the "root" of the widget hierarchy, sets the
-- required `love` callbacks, then starts the main event loop.
--
-- This method blocks until a "quit" event is received, and returns whatever
-- exit status is passed to `love.event.quit`.
--
-- @tparam kloveui.Widget root Root of the widget hierarchy.
-- @tparam ?number scale GUI scaling factor. Default is 1.
-- @treturn ?number App exit status (return value of `love.run`).
function kloveui.runsub(root, scale)
	rootwidget = root
	guiscale = scale or 1
	mousewidget = nil
	focuswidget = nil
	local ww, wh = love.window.getMode()
	local hasrep = love.keyboard.hasKeyRepeat()
	keyboard.setKeyRepeat(true)
	kloveui.resize(ww, wh)
	local function bail(...)
		rootwidget = nil
		keyboard.setKeyRepeat(hasrep)
		return ...
	end
	return bail(mainloop())
end

---
-- Run the GUI.
--
-- Equivalent to `love.event.quit(kloveui.runsub(...))`.
--
-- @tparam kloveui.Widget root Root of the widget hierarchy.
-- @tparam ?number scale GUI scaling factor. Default is 1.
function kloveui.run(root, scale)
	return love.event.quit(kloveui.runsub(root, scale))
end

return kloveui
