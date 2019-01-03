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

nofs.register_widget("pager", {
	width = 3 * nofs.fs_field_height,
	height = nofs.fs_field_height,
	handle_field_event = function(item, player_name, field, subid)
			local context = item:get_context()
			local connected = item.def.connected_to and
				item.form:get_element_by_id(item.def.connected_to)

			context.current_page = context.current_page or 1
			local old_page = context.current_page
			local max_page

			if subid == "next" then
				context.current_page = context.current_page + 1
			end
			if subid == "previous" then
				context.current_page = context.current_page - 1
			end

			if connected and connected:get_context().max_index
				and connected.def.max_items then
				max_page = math.floor((connected:get_context().max_index - 1)
					/ connected.def.max_items) + 1
			end

			if context.current_page < 1 then
				context.current_page = 1
			end
			if max_page and context.current_page > max_page then
				context.current_page = max_page
			end

			if context.current_page ~= old_page then
				if connected and connected.def.max_items then
					connected:get_context().start_index =
						1 + (context.current_page - 1) * connected.def.max_items
				end
				item.form:update()
			end
		end,
	render = function(item)
		local context = item:get_context()
		local page = context.current_page or 1
		local connected = item.def.connected_to and
			item.form:get_element_by_id(item.def.connected_to)

		local page_string = minetest.colorize("yellow", page)

		if connected and connected.def.max_items then
			if connected:get_context().max_index then
				page_string = page_string.." / "..
					(math.floor((connected:get_context().max_index - 1)
					/ connected.def.max_items) + 1)
			end
		end

		page_string = page_string or minetest_colorize("yellow", page)

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
