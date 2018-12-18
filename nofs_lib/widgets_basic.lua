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

-- Standard offset position and size
local function fspos(element, offset)
	local widgetoffset = nofs.get_widget(element.type).offset
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
	local widgetoffset = nofs.get_widget(element.type).offset
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

-- BASIC WIDGETS
----------------

nofs.register_widget("label", {
	offset = { x = 0, y = 0.2 },
	render = function(element, offset)
		local label = element.def.label or ""
		if element.def.data then
			-- TODO: check string/number but not table/function ?
			label = element.data[element.def.data]
		end
		label = minetest.formspec_escape(label)

		if element.direction and element.direction == 'vertical' then
			return string.format("vertlabel[%s;%s]", fspos(element, offset), label)
		else
			return string.format("label[%s;%s]", fspos(element, offset), label)
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
		else -- Using image buttons because normal buttons does not size vertically
			if element.exit == "true" then
				return string.format("image_button_exit[%s;;%s;%s]",
					fspossize(element, offset), element.id, element.label or "")
			else
				return string.format("image_button[%s;;%s;%s]",
					fspossize(element, offset), element.id, element.label or "")
			end
		end
	end,
})

nofs.register_widget("field", {
	holds_value = true,
	offset = { x = 0.3, y = 0.32 },
	render = function(element, offset)
		local value = element.def.value or ""
		if element.def.data then
			value = element.data[element.def.data]
		end
		value = minetest.formspec_escape(value)

		-- Render
		if element.hidden == 'true' then
			return string.format("pwdfield[%s;%s;%s]", fspossize(element, offset),
				element.id, value)
		else
			return string.format("field[%s;%s;%s;%s]", fspossize(element, offset),
				element.id, (element.def.label or ""), value)
		end
	end,
})

nofs.register_widget("checkbox", {
	holds_value = true,
	render = function(element, offset)
		return string.format("checkbox[%s;%s;%s;%s]",
			fspos(element, offset), element.id, (element.label or ""),
			element.value == "true" and "true" or "fasle")
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
