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
	local widgetoffset = element.widget.offset
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
	local widgetoffset = element.widget.offset
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

-- scrollbar
-- =========

nofs.register_widget("scrollbar", {
	handle_field_event = function(element, field)
		print(dump(minetest.explode_scrollbar_event(field)))
--		nofs.calliffunc(element.def.on_clicked) -- TODO:ARGUMENTS ?
	end,
	render = function(form, element, offset)
		form:create_id_if_missing(element)
		return string.format("scrollbar[%s;%s;%s;%s]",
			fspossize(element, offset), element.def.orientation or "vertical",
			element.id, 0) -- TODO: VALUE ??
	end,
})

-- label
-- =====
-- Attributes:
--  - width, height
--	- label
-- Triggers:
--  none

nofs.register_widget("label", {
	offset = { x = 0, y = 0.2 },
	render = function(form, element, offset)
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

-- button
-- ======
-- Attributes:
--  - width, height
--	- label
--  - image
--  - item
--  - exit
-- Triggers:
--  - on_clicked

nofs.register_widget("button", {
	handle_field_event = function(element, field)
		nofs.calliffunc(element.def.on_clicked) -- TODO:ARGUMENTS ?
	end,
	render = function(form, element, offset)
		-- Some warnings
		if element.def.item ~= nil then
			if element.def.image ~= nil then
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

		form:create_id_if_missing(element)

		-- Now, render !
		if element.def.image then
			if element.exit == "true" then
				return string.format("image_button_exit[%s;%s;%s;%s]",
					fspossize(element, offset), element.def.image, element.id,
					element.def.label or "")
			else
				return string.format("image_button[%s;%s;%s;%s]",
					fspossize(element, offset), element.def.image, element.id,
					element.def.label or "")
			end
		elseif element.item then
			return string.format("item_image_button[%s;%s;%s;%s]",
				fspossize(element, offset), element.def.item, element.id,
				element.def.label or "")
		else -- Using image buttons because normal buttons does not size vertically
			if element.def.exit == "true" then
				return string.format("image_button_exit[%s;;%s;%s]",
					fspossize(element, offset), element.id, element.def.label or "")
			else
				return string.format("image_button[%s;;%s;%s]",
					fspossize(element, offset), element.id, element.def.label or "")
			end
		end
	end,
})


-- Field
-- =====
-- Attributes:
--  - width, height
--	- label
--  - data
--  - hidden
-- Triggers:
--  - on_changed

nofs.register_widget("field", {
	holds_value = true,
	offset = { x = 0.3, y = 0.32 },
	handle_field_event = function(element, field)
		if element.value ~= field then
			local value = element.value
			element.value = field
			-- TODO:Arguments
			nofs.calliffunc(element.def.on_changed, value)
		end
		element.value = field
	end,
	render = function(form, element, offset)
		form:create_id_if_missing(element)
		local value = element.value or ""
		-- TODO : Should data be managed here or when validating ?
		if element.def.data then
			value = element.data[element.def.data]
		end
		value = minetest.formspec_escape(value)

		-- Render
		if element.def.hidden == 'true' then
			return string.format("pwdfield[%s;%s;%s]", fspossize(element, offset),
				element.id, value)
		else
			return string.format("field[%s;%s;%s;%s]", fspossize(element, offset),
				element.id, (element.def.label or ""), value)
		end
	end,
})

-- Checkbox
-- ========
-- Attributes:
--  - width, height
--	- label
-- Triggers:
--  - on_clicked
--  - on_changed

nofs.register_widget("checkbox", {
	holds_value = true,
	handle_field_event = function(element, field)
		if element.value ~= field then
			local value = element.value
			element.value = field
			-- TODO:Arguments
			nofs.calliffunc(element.def.on_changed, value)
		end
		nofs.calliffunc(element.def.on_clicked) -- TODO:ARGUMENTS ?
	end,
	render = function(form, element, offset)
		form:create_id_if_missing(element)
		return string.format("checkbox[%s;%s;%s;%s]",
			fspos(element, offset), element.id, (element.def.label or ""),
			element.value == "true" and "true" or "fasle")
	end,
})

nofs.register_widget("inventory", {
	render = function(form, element, offset)
		form:create_id_if_missing(element)
		return string.format("list[%s;%s;%s;]%s",
			element.def.inventory or "current_player",
			element.def.list or "main",
			fspossize(element, offset),
			element.def.listring and "listring[]" or "")
		end,
})
