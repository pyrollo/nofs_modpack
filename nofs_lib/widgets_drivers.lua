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

-- SCROLLBAR
------------

function index_to_value(index, min_index, max_index, max_value)
    return math.floor(
			(index - min_index) * max_value / (max_index - min_index) + 0.5)
end

function value_to_index(value, min_index, max_index, max_value)
    return math.floor(
			min_index + 0.5 + value * (max_index - min_index) / max_value)
end

-- scrollbar
-- =========

nofs.register_widget("scrollbar", {
	-- This is a bit complex. Default scrollbar management have big issues.
	-- Main one is that if form is refreshed while dragging the scrollbar cursor
	-- then mouse looses the cursor. Have to temporize before actually refresh the
	-- form
	dynamic = { value = 0 },
	handle_field_event = function(item, field)
		local event = minetest.explode_scrollbar_event(field)
		if event.type == 'CHG' then
			local value = item:get_context('value')
			event.increase = event.value > (value or 0)
			event.decrease = event.value < (value or 0)
			local connected =
				item.form:get_element_by_id(item.def.connected_to)
			local min_index, max_index
			if connected then
				min_index = connected:get_context('min_index') or 1
				max_index = connected:get_context('max_index') or 1

				if max_index - min_index > 0 then
					local index = value_to_index(event.value, min_index, max_index, 1000)

					-- If index unchanged, force to go to next index
					-- according to direction
					if index == (connected:get_context('start_index') or 1)
					then
						if event.increase and index < max_index then
							index = index + 1
						end
						if event.decrease and index > min_index then
							index = index - 1
						end
					end

					connected:set_context('start_index', index)
					event.value =	index_to_value(index, min_index, max_index, 1000)
				end
			end

			item:set_context('value', event.value)
			item:set_context('update', (item:get_context('update') or 0) + 1)

			minetest.after(0.1, function()
				item:set_context('update',  item:get_context('update') - 1)
				if item:get_context('update') == 0 then
					item.form:refresh()
				end
			end)
		end
	end,

	render = function(item)
		local connected =
			item.form:get_element_by_id(item.def.connected_to)

		local value = item:get_context('value') or 0
		if connected then
			value = index_to_value(
				connected:get_context('start_index') or 1,
				connected:get_context('min_index') or 1,
				connected:get_context('max_index') or 1,
				1000)
		end

		return nofs.fs_element_string('scrollbar',
			item.geometry, item.def.orientation or "vertical", item.id, value)
	end,
})

-- PAGER
--------

local function index_to_page(index, min_index, ix_per_page)
	return math.floor((index - min_index) / ix_per_page + 1)
end

local function page_to_index(page, min_index, ix_per_page)
	return min_index + (page - 1) * ix_per_page
end

local function nb_of_pages(min_index, max_index, ix_per_page)
	return math.floor((max_index - min_index) / ix_per_page) + 1
end

local function get_page_vars(item, connected)
	if connected then
		local min_index = connected:get_context('min_index') or 1
		local max_index = connected:get_context('max_index') or 1
		local step_index = connected:get_attribute('max_items') or 1
		return
			min_index, max_index, step_index,
			index_to_page(connected:get_context('start_index') or 1,
			min_index, step_index),
			nb_of_pages(min_index, max_index, step_index)
	else
		return nil, nil, nil, item:get_attribute('page'), nil
	end
end

nofs.register_widget("pager", {
	width = 3 * nofs.fs_field_height,
	height = nofs.fs_field_height,
	componants = { 'next', 'previous', 'label', 'mask' },
	dynamic = { page = 1 },

	handle_field_event = function(item, fieldvalue, fieldname)
			local component = fieldname:match("[.]([^.]*)$")

			if component == "next" or component == "previous" then
				local connected = item.def.connected_to and
					item.form:get_element_by_id(item.def.connected_to)
				local min_index, max_index, step_index, page, max_page =
					get_page_vars(item, connected)

				local old_page = page

				if component == "next" then	page = page + 1 end
				if component == "previous" then page =page - 1 end

				if page < 1 then page = 1 end
				if max_page and page > max_page then page = max_page end

				if page ~= old_page then
					if connected then
						connected:set_context('start_index',
							page_to_index(page, min_index, step_index))
					end
					item.form:update()
				end
			end
		end,

	render = function(item)
		local connected = item.def.connected_to and
			item.form:get_element_by_id(item.def.connected_to)

		local min_index, max_index, step_index, page, max_page =
			get_page_vars(item, connected)

		local page_string = minetest.colorize("yellow", page)

		if connected then
			page_string = page_string.." / "..
				nb_of_pages(min_index, max_index, step_index)
		end

		return nofs.fs_element_string('image_button',
			{	x = item.geometry.x,
				y = item.geometry.y,
				w = item.geometry.w/4,
				h = item.geometry.h},
			"", item.id..".previous","<")
		..nofs.fs_element_string('image_button',
			{	x = item.geometry.x + item.geometry.w*1/4,
				y = item.geometry.y,
				w = item.geometry.w/2,
				h = item.geometry.h},
			"", item.id..".label", page_string, "false", "false", "")
		..nofs.fs_element_string('image_button',
			{	x = item.geometry.x + item.geometry.w*1/4,
				y = item.geometry.y,
				w = item.geometry.w/2,
				h = item.geometry.h},
			"", item.id..".mask", "", "false", "false", "")
		..nofs.fs_element_string('image_button',
			{	x = item.geometry.x + item.geometry.w*3/4,
				y = item.geometry.y,
				w = item.geometry.w/4 ,
				h = item.geometry.h},
			"", item.id..".next",">")
		end,
})
