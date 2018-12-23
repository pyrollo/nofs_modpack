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
local function fspos(item, offset)
	local widgetoffset = item.widget.offset
	if widgetoffset then
		return string.format("%g,%g",
			item.pos.x + offset.x + widgetoffset.x,
			item.pos.y + offset.y + widgetoffset.y)
	else
		return string.format("%g,%g",
			item.pos.x + offset.x, item.pos.y + offset.y)
	end
end

local function fspossize(item, offset)
	local widgetoffset = item.widget.offset
	if widgetoffset then
		return string.format("%g,%g;%g,%g",
			item.pos.x + offset.x + widgetoffset.x,
			item.pos.y + offset.y + widgetoffset.y,
			item.size.x, item.size.y)
	else
		return string.format("%g,%g;%g,%g",
			item.pos.x + offset.x, item.pos.y + offset.y,
			item.size.x, item.size.y)
	end
end

-- BASIC WIDGETS
----------------

local function scrollbar_get_index(value, min, max)
	return math.floor(value / 1000 * (max-min)) + min
end
local function scrollbar_get_value(index, min, max)
	return math.floor(1000 * (index-min) / ((max-min) or 1 ))
end

-- scrollbar
-- =========

nofs.register_widget("scrollbar", {
	handle_field_event = function(item, field)
--		nofs.calliffunc(item.def.on_clicked) -- TODO:ARGUMENTS ?
		local event = minetest.explode_scrollbar_event(field)
		local context = item:get_context()
		if event.type == 'CHG' then
			event.increase = event.value > (context.value or 0)
			event.decrease = event.value < (context.value or 0)
			context.value = event.value

			if item.def.connected_to then
				local connected =
					item.form:get_element_by_id(item.def.connected_to)
				if connected.def.max_items then
					local max_index = #connected - connected.def.max_items
					local start_index = 1
					if max_index > 1 then
						start_index = scrollbar_get_index(event.value, 1, max_index)
						if start_index == connected:get_context().start_index
						then
							if event.increase and start_index < max_index then
								start_index = start_index + 1
							end
							if event.decrease and start_index > 1 then
								start_index = start_index - 1
							end
						end
					end
					connected:get_context().start_index = start_index
					context.value = scrollbar_get_value(start_index, 1, max_index)
				end
			end
		end
--[[
		if type == 'CHG' then
			if element.connected_to then
				local connect = form:get_element_by_id(element.connected_to)
				connect.def.max_items
				connect.data.start_index
				#connect

		end]]
	end,
	render = function(item, offset)
		item:have_an_id()
		return string.format("scrollbar[%s;%s;%s;%s]",
			fspossize(item, offset), item.def.orientation or "vertical",
			item.id, item:get_context().value or 0) -- TODO: VALUE ??
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
	render = function(item, offset)
		local label = item.def.label or ""
		if item.def.data then
			-- TODO: check string/number but not table/function ?
			label = item.data[item.def.data]
		end
		label = minetest.formspec_escape(label)

		if item.direction and item.direction == 'vertical' then
			return string.format("vertlabel[%s;%s]", fspos(item, offset), label)
		else
			return string.format("label[%s;%s]", fspos(item, offset), label)
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
	handle_field_event = function(item, field)
		nofs.calliffunc(item.def.on_clicked) -- TODO:ARGUMENTS ?
	end,
	render = function(item, offset)
		-- Some warnings
		if item.def.item ~= nil then
			if item.def.image ~= nil then
				minetest.log('warning',
					'Button can\'t have "image" and "item" attributes at once. '..
					'Ignoring "item" attribute.')
			end
			if item.exit == 'true' then
				minetest.log('warning',
					'Button can\'t have exit=true and item attributes at once. '..
					'Ignoring exit=true attribute.')
			end
		end

		item:have_an_id()

		-- Now, render !
		if item.def.image then
			if item.exit == "true" then
				return string.format("image_button_exit[%s;%s;%s;%s]",
					fspossize(item, offset), item.def.image, item.id,
					item.def.label or "")
			else
				return string.format("image_button[%s;%s;%s;%s]",
					fspossize(item, offset), item.def.image, item.id,
					item.def.label or "")
			end
		elseif item.item then
			return string.format("item_image_button[%s;%s;%s;%s]",
				fspossize(item, offset), item.def.item, item.id,
				item.def.label or "")
		else -- Using image buttons because normal buttons does not size vertically
			if item.def.exit == "true" then
				return string.format("image_button_exit[%s;;%s;%s]",
					fspossize(item, offset), item.id, item.def.label or "")
			else
				return string.format("image_button[%s;;%s;%s]",
					fspossize(item, offset), item.id, item.def.label or "")
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
	handle_field_event = function(item, field)
		if item.value ~= field then
			local value = item.value
			item.value = field
			-- TODO:Arguments
			nofs.calliffunc(item.def.on_changed, value)
		end
		item.value = field
	end,
	render = function(item, offset)
		item:have_an_id()
		local value = item.value or ""
		-- TODO : Should data be managed here or when validating ?
		if item.def.data then
			value = item.data[item.def.data]
		end
		value = minetest.formspec_escape(value)

		-- Render
		if item.def.hidden == 'true' then
			return string.format("pwdfield[%s;%s;%s]", fspossize(item, offset),
				item.id, value)
		else
			return string.format("field[%s;%s;%s;%s]", fspossize(item, offset),
				item.id, (item.def.label or ""), value)
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
	handle_field_event = function(item, field)
		if item.value ~= field then
			local value = item.value
			item.value = field
			-- TODO:Arguments
			nofs.calliffunc(item.def.on_changed, value)
		end
		nofs.calliffunc(item.def.on_clicked) -- TODO:ARGUMENTS ?
	end,
	render = function(item, offset)
		item:have_an_id()
		return string.format("checkbox[%s;%s;%s;%s]",
			fspos(item, offset), item.id, (item.def.label or ""),
			item.value == "true" and "true" or "fasle")
	end,
})

nofs.register_widget("inventory", {
	render = function(item, offset)
		item:have_an_id()
		return string.format("list[%s;%s;%s;]%s",
			item.def.inventory or "current_player",
			item.def.list or "main",
			fspossize(item, offset),
			item.def.listring and "listring[]" or "")
		end,
})
