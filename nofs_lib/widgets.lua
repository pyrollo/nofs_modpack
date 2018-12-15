--[[
	nofs_lib for Minetest - NO FormSpec API
	(c) Pierre-Yves Rollo

	This file is part of nofs_lib.

	signs is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	signs is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with signs.  If not, see <http://www.gnu.org/licenses/>.
--]]

local widgets = {}

function nofs.register_widget(type_name, def)
	assert(widgets[type_name] == nil,
		string.format('Widget type "%s" already registered.', type_name))
	widgets[type_name] = table.copy(def)
end

function nofs.get_widget(type_name)
	return widgets[type_name]
end

-- Standard offset position and size
local function fspos(element, offset)
	local widgetoffset = widgets[element.type].offset
	if widgetoffset then
		return string.format("%g,%g",
			element.pos.x + offset.x + widgetoffset.x,
			element.pos.y + offset.y + widgetoffset.y)
	else
		return string.format("%g,%g",
			element.pos.x + offset.x, element.pos.y + offset.y)
	end
end

local function fspossize(element, offset)
	local widgetoffset = widgets[element.type].offset
	if widgetoffset then
		return string.format("%g,%g;%g,%g",
			element.pos.x + offset.x + widgetoffset.x,
			element.pos.y + offset.y + widgetoffset.y,
			element.size.x, element.size.y)
	else
		return string.format("%g,%g;%g,%g",
			element.pos.x + offset.x, element.pos.y + offset.y,
			element.size.x, element.size.y)
	end
end

-- Sizing vbox and hbox and places child elements inside
--
local function size_box(element, boxtype)
	local main, other
	local pos = 0 -- TODO:MARGIN
	local size = 0

	-- Process vbox and hbox the same way, just inverting coordinates
	if boxtype == 'h' then
		main = 'x' other = 'y'
	else
		main = 'y' other = 'x'
	end

	-- Main positionning and other size
	for _, child in ipairs(element) do
		child.pos = { [main] = pos, [other] = 0 }
		pos = pos + child.size[main] -- TODO:Spacing
		if child.size[other] > size then
			size = child.size[other]
		end
	end

	-- Other positionning
	for _, child in ipairs(element) do
		-- TODO: This is center, add left & right
		child.pos[other] =
			( size - child.size[other] ) / 2
	end

	element.size = { [main] = pos, [other] = size }
end

-- Containers generic rendering
--
local function render_container(element, offset)
	local inneroffset = {
		x = offset.x + element.pos.x,
		y = offset.y + element.pos.y
	}
	local fs = ""
	for _, child in ipairs(element) do
		local widget = nofs.get_widget(child.type)
		if widget.render then
			fs = fs..widget.render(child, inneroffset)
		end
	end
	return fs
end

-- CONTAINERS WIDGETS
---------------------

nofs.register_widget("vbox", {
	size = function(element) size_box(element, 'v') end,
	render = render_container,
})

nofs.register_widget("hbox", {
	size = function(element) size_box(element, 'h') end,
	render = render_container,
})

-- BASIC WIDGETS
----------------

nofs.register_widget("label", {
	offset = { x = 0, y = 0.2 },
	render = function(element, offset)
		if element.direction and element.direction == 'vertical' then
			return string.format("vertlabel[%s;%s]",
				fspos(element, offset), (element.label or ""))
		else
			return string.format("label[%s;%s]",
				fspos(element, offset), (element.label or ""))
		end
	end,
})

nofs.register_widget("button", {
	needs_id = true,
	render = function(element, offset)
		-- Some warnings
		if element.item ~= nil then
			if element.image ~= nil then
				minetest.log('warning',
					'Button can\'t have "image" and "item" attributes at once. '..
					'Ignoring "item" attribute.')
			end
			if element.exit == 'true' then
				minetest.log('warning',
					'Button can\'t have exit=true and item attributes at once. '..
					'Ignoring exit=true attribute.')
			end
		end

		-- Now, render !
		if element.image then
			if element.exit == "true" then
				return string.format("image_button_exit[%s;%s;%s;%s]",
					fspossize(element, offset), element.image, element.id,
					element.label or "")
			else
				return string.format("image_button[%s;%s;%s;%s]",
					fspossize(element, offset), element.image, element.id,
					element.label or "")
			end
		elseif element.item then
			return string.format("item_image_button[%s;%s;%s;%s]",
				fspossize(element, offset), element.item, element.id,
				element.label or "")
		else
			if element.exit == "true" then
				return string.format("button_exit[%s;%s;%s]",
					fspossize(element, offset), element.id, element.label or "")
			else
				return string.format("button[%s;%s;%s]",
					fspossize(element, offset), element.id, element.label or "")
			end
		end
	end,
})

nofs.register_widget("field", {
	needs_id = true,
	offset = { x = 0.3, y = 0.32 },
	render = function(element, offset)
		-- Some warnings
		if element.hidden == 'true' then
			if element.default ~= nil then
				minetest.log('warning',
					'Hidden field can\'t have a default value. Ignoring "default" attribute.')
			end
		end

		-- Render
		if element.hidden == 'true' then
			return string.format("pwdfield[%s;%s;%s]", fspossize(element, offset),
				element.id, (element.label or ""))
		else
			return string.format("field[%s;%s;%s;%s]", fspossize(element, offset),
				element.id, (element.label or ""), (element.default or ""))
		end
	end,
})

nofs.register_widget("checkbox", {
	needs_id = true,
	render = function(element, offset)
		return string.format("checkbox[%s;%s;%s;%s]",
			fspos(element, offset), element.id, (element.label or ""),"true")
	end,
})

nofs.register_widget("inventory", {
	render = function(element, offset)
		return string.format("list[%s;%s;%s;]%s",
			element.inventory or "current_player",
			element.list or "main",
			fspossize(element, offset),
			element.listring and "listring[]" or "")
		end,
})
