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
			print(subid)
		end,
	render = function(item, offset)
		item:have_an_id()
		return nofs.fs_element_string('image_button',
			nofs.add_offset({
				x = item.geometry.x,
				y = item.geometry.y,
				w = item.geometry.w/4,
				h = item.geometry.h}, offset),
			"", item.id..".left","<")
		..nofs.fs_element_string('image_button',
			nofs.add_offset({
				x = item.geometry.x + item.geometry.w*1/4,
				y = item.geometry.y,
				w = item.geometry.w/2,
				h = item.geometry.h}, offset),
			"", item.id..".label",minetest.colorize("yellow", "XX").."/XX", "false", "false", "")
		..nofs.fs_element_string('image_button',
			nofs.add_offset({
				x = item.geometry.x + item.geometry.w*3/4,
				y = item.geometry.y,
				w = item.geometry.w/4 ,
				h = item.geometry.h}, offset),
			"", item.id..".right",">")
		end,
})
