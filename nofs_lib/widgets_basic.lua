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

local function save_to_meta(item, name)
	local meta = item:get_attribute('meta')
	if meta then
		item.form:set_meta(meta, item:get_attribute(name))
	end
end

local function load_from_meta(item, name)
	local meta = item:get_attribute('meta')
	if meta then
		item:set_context(name, item.form:get_meta(meta))
	end
end

local function load_from_data(item, name)
	local data = item:get_attribute('data')
	if data then
		item:set_context(name, item:get_data(data))
	end
end

-- BASIC WIDGETS
----------------

-- label
-- =====

nofs.register_widget("label", {
	height = nofs.fs_field_height,
	dynamic = { label = "" },
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
	dynamic = { label = "", item = "", image = "" },
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

			if a_item ~= "" then
				return nofs.fs_element_string('item_image_button',
					item.geometry, fsesc(a_item), item.id,
					fsesc(item:get_attribute('label')))
			else
				-- Using image buttons because normal buttons does not size vertically
				if item.def.exit == true then
					return nofs.fs_element_string('image_button_exit',
						item.geometry, fsesc(a_image), item.id,
						fsesc(item:get_attribute('label')))
				else
					return nofs.fs_element_string('image_button',
						item.geometry, fsesc(a_image), item.id,
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
	dynamic = { value = "", label = "" },
	init = function(item)
		load_from_meta(item, 'value')
	end,
	handle_field_event = function(item, field)
		local oldvalue = item:get_attribute('value')
		item:set_context('value', field)
		if oldvalue ~= field then
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
		save_to_meta(item, 'value')
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
	dynamic = { value = "", label = "" },
	init = function(item)
		load_from_meta(item, 'value')
	end,
	handle_field_event = function(item, field)
		local oldvalue = item:get_attribute('value')
		item:set_context('value', field)
		if oldvalue ~= field then
			item:trigger('on_changed', oldvalue)
		end
	end,
	render = function(item)
		return nofs.fs_element_string('textarea',
			item.geometry, item.id, fsesc(item:get_attribute('label')),
			fsesc(item:get_attribute('value')))
	end,
	save = function(item)
		save_to_meta(item, 'value')
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
	dynamic = { value = false, label = "" },
	init = function(item)
			load_from_meta(item, 'value')
		end,
	handle_field_event = function(item, field)
			local oldvalue = item:get_attribute('value')
			item:set_context('value', field == 'true')
			if oldvalue ~= field then
				item:trigger('on_changed', oldvalue)
			end
			item:trigger('on_clicked')
		end,
	render = function(item)
			return nofs.fs_element_string('checkbox',
				item.geometry, item.id,
				fsesc(item:get_attribute('label')),
				item:get_attribute('value') and "true" or "false")
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
	dynamic = { start_index = 1 },
	render = function(item, offset)
			return nofs.fs_element_string('list', item.geometry,
				-- TODO : link node inventory to form's node
				item:get_attribute('location') or "",
				item:get_attribute('list') or "",
				item:get_attribute('start_index') or "")
		end,
})
