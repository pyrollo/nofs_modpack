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
	handle_field_event = function(item, field)
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
					-- TODO manage the case when max_index does not exist
					local max_index = connected:get_context().max_index
						- connected.def.max_items + 1

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
					context.value = scrollbar_get_value(start_index, 1, max_index)
					context.update = (context.update or 0) + 1
					minetest.after(0.1, function()
						context.update = context.update - 1
						if context.update == 0 then
							item.form:refresh()
						end
					end)
				end
			end
		end
	end,
	render = function(item)
		return nofs.fs_element_string('scrollbar',
			item.geometry,
			item.def.orientation or "vertical",
			item:get_id(), fsesc(item:get_attribute("value") or 0))
	end,
})

-- label
-- =====
-- Attributes:
--	- width, height
--	- label (contextualizable)
-- Triggers:
--	- init

nofs.register_widget("label", {
	height = nofs.fs_field_height,
	render = function(item)
			-- Use of textarea is much better than label as text is actually
			-- limited to the giver area and label can be multiline
			return nofs.fs_element_string('textarea', item.geometry,
				'', fsesc(item:get_attribute('label')), '')
		end,
})

-- button
-- ======

nofs.register_widget("button", {
	height = nofs.fs_field_height,
	width = 2,
	init = function(item)
			if item:get_attribute('item') and item:get_attribute('image') then
				minetest.log('warning',
					'Button can\'t have "image" and "item" attributes at once. '..
					'Ignoring "image" attribute.')
			end
		end,
	handle_field_event = function(item, field)
			item:trigger('on_clicked')
		end,
	render = function(item)
			local a_item = item:get_attribute('item')
			local a_image = item:get_attribute('image')

			if a_item then
				return nofs.fs_element_string('item_image_button',
					item.geometry, fsesc(a_item), item:get_id(),
					fsesc(item:get_attribute('label')))
			else
				-- Using image buttons because normal buttons does not size vertically
				if item.def.exit == true then
					return nofs.fs_element_string('image_button_exit',
						item.geometry, offset, fsesc(a_image), item:get_id(),
						fsesc(item:get_attribute('label')))
				else
					return nofs.fs_element_string('image_button',
						item.geometry, fsesc(a_image), item:get_id(),
						fsesc(item:get_attribute('label')))
				end
			end
		end,
})

-- Field
-- =====

nofs.register_widget("field", {
	height = nofs.fs_field_height,
	width = 2,
	init = function(item)
		local context = item:get_context()
		if item.def.meta then
			context.value = context.value or item.form:get_meta(item.def.meta)
		end
	end,
	handle_field_event = function(item, field)
		local context = item:get_context()
		local oldvalue = context.value or ''
		context.value = field
		if context.value ~= oldvalue then
			item:trigger('on_changed', oldvalue)
		end
	end,
	render = function(item)
		-- Render
		if item.def.hidden == true then
			return nofs.fs_element_string('pwdfield', item.geometry, item.id,
				fsesc(item:get_attribute('value')))
		else
			return nofs.fs_element_string('field', item.geometry, item.id,
				fsesc(item:get_attribute('label')), fsesc(item:get_attribute('value')))
		end
	end,
	save = function(item)
		-- Save to meta
		if item.def.meta then
			item.form:set_meta(item.def.meta, item:get_context().value)
		end
	end,
})

-- Textarea
-- ========
-- Attributes:
--	- width, height
--	- label (contextualizable)
--	- value (contextualizable)
--	- meta
-- Triggers:
--	- init
--	- on_changed

nofs.register_widget("textarea", {
	height = 3,
	width = 3,
	init = function(item)
		local context = item:get_context()
		if item.def.meta then
			context.value = context.value or item.form:get_meta(item.def.meta)
		end
	end,
	handle_field_event = function(item, field)
		local context = item:get_context()
		local oldvalue = context.value or ''
		context.value = field
		if context.value ~= oldvalue then
			item:trigger('on_changed', oldvalue)
		end
	end,
	render = function(item)
		return nofs.fs_element_string('textarea',
			item.geometry, item:get_id(), fsesc(item:get_attribute('label')),
			fsesc(item:get_attribute('value')))
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
			local context = item:get_contect()
			if item.def.meta then
				context.value = context.value or item.form:get_meta(item.def.meta)
			end
		end,
	handle_field_event = function(item, field)
			local context = item:get_context()
			local oldvalue = item.value
			context.value = field
			if context.value ~= oldvalue then
				item:trigger('on_changed', oldvalue)
			end
			item:trigger('on_clicked')
		end,
	render = function(item)
			return nofs.fs_element_string('checkbox',
				item.geometry, item:get_id(),
				fsesc(item:get_attribute('label')),
				item:get_attribute('value') == "true" and "true" or "false")
		end,
})


-- Inventory
-- =========
-- Attributes:
--	- location (contextualizable) : current_player, node
--	- list (contextualizable) : name of the inventory list
--	- listring : belongs to the listring or not
-- Context:
--	- start_index

nofs.register_widget("inventory", {
	render = function(item, offset)
			return nofs.fs_element_string('list', item.geometry,
				-- TODO : link node inventory to form's node
				item:get_attribute('location') or "",
				item:get_attribute('list') or "",
				item:get_context().start_item or "")
		end,
})
