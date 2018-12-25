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

local function fsesc(text)
	return minetest.formspec_escape(text or '')
end

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
-- Attributes
--	- width, height
--	- orientation
--	- value (contextualizable)
-- Triggers
--	- init

nofs.register_widget("scrollbar", {
	-- This is a bit complex. Default scrollbar management have big issues.
	-- Main one is that if form is refreshed while dragging the scrollbar cursor
	-- then mouse looses the cursor. Have to temporize before actually refresh the
	-- form
	handle_field_event = function(item, player_name, field)
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
					local max_index = #connected - connected.def.max_items + 1
					local start_index = 1
					if max_index > 1 then
						start_index = scrollbar_get_index(event.value, 1, max_index)
						-- If index unchanged, force to go to next index
						-- according to direction
						if start_index == (connected:get_context().start_index or 1)
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
					print(start_index)
					context.value = scrollbar_get_value(start_index, 1, max_index)
					context.update = (context.update or 0) + 1
					minetest.after(0.1, function()
						context.update = context.update - 1
						if context.update == 0 then
							nofs.refresh_form(player_name)
						end
					end)
				end
			end
		end
	end,
	render = function(item, offset)
		item:have_an_id()
		return string.format("scrollbar[%s;%s;%s;%s]",
			fspossize(item, offset), item.def.orientation or "vertical",
			item.id, fsesc(item:get_attribute("value") or 0))
	end,
})

-- label
-- =====
-- Attributes:
--	- width, height
--	- label (contextualizable)
--	- direction
-- Triggers:
--	- init

nofs.register_widget("label", {
	offset = { x = 0, y = 0.2 },
	render = function(item, offset)
			local alabel = fsesc(item:get_attribute('label'))
			if item.def.direction and item.def.direction == 'vertical' then
				return string.format("vertlabel[%s;%s]", fspos(item, offset), alabel)
			else
				-- Use of textarea is much better than label as text is actually
				-- limited to the giver area and label can be multiline
				return string.format("textarea[%s;;%s;]",
					fspossize(item, offset, alabel), alabel)
			end
		end,
})

-- button
-- ======
-- Attributes:
--	- width, height
--	- label (contextualizable)
--	- image (contextualizable)
--	- item (contextualizable)
--	- exit
-- Triggers:
--	- init
--	- on_clicked

nofs.register_widget("button", {
	init = function(item)
			item:have_an_id()
			if item:get_attribute('item') and item:get_attribute('image') then
				minetest.log('warning',
					'Button can\'t have "image" and "item" attributes at once. '..
					'Ignoring "image" attribute.')
			end
		end,
	handle_field_event = function(item, player_name, field)
			item:trigger('on_clicked')
		end,
	render = function(item, offset)
			local aitem = item:get_attribute('item')
			local aimage = item:get_attribute('image')
			local alabel = item:get_attribute('label')

			if aitem then
				return string.format("item_image_button[%s;%s;%s;%s]",
					fspossize(item, offset), fsesc(aitem), item.id, fsesc(alabel))
			else
				-- Using image buttons because normal buttons does not size vertically
				if item.def.exit == "true" then
					return string.format("image_button_exit[%s;%s;%s;%s]",
						fspossize(item, offset), fsesc(aimage), item.id, fsesc(alabel))
				else
					return string.format("image_button[%s;%s;%s;%s]",
						fspossize(item, offset), fsesc(aimage), item.id, fsesc(alabel))
				end
			end
		end,
})


-- Field
-- =====
-- Attributes:
--	- width, height
--	- label (contextualizable)
--	- value (contextualizable)
--	- hidden
--	- meta
-- Triggers:
--	- init
--	- on_changed

nofs.register_widget("field", {
	holds_value = true,
	offset = { x = 0.3, y = 0.32 },
	init = function(item)
		item:have_an_id()
		local context = item:get_context()
		if item.def.meta then
			context.value = context.value or item.form:get_meta(item.def.meta)
		end
	end,
	handle_field_event = function(item, player_name, field)
		local context = item:get_context()
		local oldvalue = context.value or ''
		context.value = field
		if context.value ~= oldvalue then
			item:trigger('on_changed', oldvalue)
		end
	end,
	render = function(item, offset)
		local context = item:get_context()
		local avalue = item:get_attribute('value')
		local alabel = item:get_attribute('label')
		-- Render
		if item.def.hidden == 'true' then
			return string.format("pwdfield[%s;%s;%s]",
				fspossize(item, offset), item.id, fsesc(avalue))
		else
			return string.format("field[%s;%s;%s;%s]",
				fspossize(item, offset), item.id, fsesc(alabel), fsesc(avalue))
		end
	end,
	save = function(item)
		-- Save to meta
		if item.def.meta then
			item.form:set_meta(item.def.meta, item:get_context().value)
		end
	end,
})

-- Checkbox
-- ========
-- Attributes:
--  - width, height
--	- label
-- Triggers:
--  - on_clicked(item)
--  - on_changed(item, oldvalue)
-- Context:
--  value: value of the checkbox

nofs.register_widget("checkbox", {
	init = function(item)
			item:have_an_id()
			local context = item:get_contect()
			if item.def.meta then
				context.value = context.value or item.form:get_meta(item.def.meta)
			end
		end,
	handle_field_event = function(item, player_name, field)
			local context = item:get_context()
			local oldvalue = item.value
			context.value = field
			if context.value ~= oldvalue then
				item:trigger('on_changed', oldvalue)
			end
			item:trigger('on_clicked')
		end,
	render = function(item, offset)
			item:have_an_id()
			local alabel = item:get_attribute('label')
			local avalue = item:get_attribute('value')
			return string.format("checkbox[%s;%s;%s;%s]",
				fspos(item, offset), item.id, fsasc(alabel),
				avalue == "true" and "true" or "false")
		end,
})

-- WIP
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
