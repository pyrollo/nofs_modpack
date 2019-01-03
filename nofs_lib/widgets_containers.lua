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

local function align_position(item_geo, box_geo, halign, valign)
	if valign == 'top' then
		item_geo.y = box_geo.y
	elseif valign == 'bottom' then
		item_geo.y = box_geo.y + box_geo.h - item_geo.h
	else
		item_geo.y = box_geo.y + box_geo.h / 2 - item_geo.h / 2
	end

	if halign == 'left' then
		item_geo.x = box_geo.x
	elseif halign == 'right' then
		item_geo.x = box_geo.x + box_geo.w - item_geo.w
	else
		item_geo.x = box_geo.x + box_geo.w / 2 - item_geo.w / 2
	end
end

local container_scrollbar_width = 0.5

-- Sizing vbox and hbox and places child items inside
local function lay_out_box(item)
	local ix_pos_main, ix_pos_other, ix_size_main, ix_size_other
	local spacing = item:get_def_inherit('spacing') or 0

	-- Process vbox and hbox the same way, just inverting coordinates
	if item.widget.orientation == 'horizontal' then
		ix_pos_main, ix_pos_other, ix_size_main, ix_size_other = 'x', 'y', 'w', 'h'
	else
		ix_pos_main, ix_pos_other, ix_size_main, ix_size_other = 'y', 'x', 'h', 'w'
	end

	local size_main, size_other, pos_main, overlap_size = 0, 0, -spacing, 0

	-- size_other = max child size
	for _, child in ipairs(item) do
		if child.geometry[ix_size_other] > size_other then
			size_other = child.geometry[ix_size_other]
		end
	end

	local start_index = item:get_context().start_index or 1

	-- Positionning and size_main (=sum child sizes)
	for index, child in ipairs(item) do
		if not item.def.max_items or
			index >= start_index and index < start_index + item.def.max_items
		then
			if child.widget.overlapping then
				overlap_size = math.max(overlap_size, child.geometry[ix_size_main])
			elseif overlap_size > 0 then
				pos_main = pos_main + spacing + overlap_size
				overlap_size = 0
			end

			align_position(
				child.geometry,
				{ [ix_pos_main] = pos_main + spacing,
					[ix_pos_other] = 0,
					[ix_size_main] = child.geometry[ix_size_main],
					[ix_size_other] = size_other },
				item.def.halign or "center", item.def.valign or "middle")

			size_main = math.max(size_main,
				pos_main + spacing + child.geometry[ix_size_main])

			if not child.widget.overlapping then
				pos_main = pos_main + spacing + child.geometry[ix_size_main]
			end
		end
	end

  -- Improvements needed for overflow managing (type, positionning, visibility)
	if item.def.overflow and item.def.overflow == 'scrollbar' then
		size_other = size_other + spacing + container_scrollbar_width
	end

	-- Finally set box size according to previous findings
	item.geometry[ix_size_main] = size_main
	item.geometry[ix_size_other] = size_other
end

-- Containers generic rendering
--
local function render_container(item)

	local start_index = item:get_context().start_index or 1

	local overflow = false

	local fs = ""
	for index, child in ipairs(item) do
		if item.def.max_items and
			(index < start_index or index >= start_index + item.def.max_items)
		then
			overflow = true
		else
			fs = fs..child:render()
		end
	end

	item:get_context().max_index = #item

	if overflow and item.def.overflow and item.def.overflow == 'scrollbar'
	then
		local scrollbar = nofs.new_item(item, {
				type = 'scrollbar',
				orientation = item.widget.orientation,
				connected_to = item.id,
			})

		if item.def.orientation == 'horizontal' then
			scrollbar.geometry = {
				x = item.geometry.x,
				y = item.geometry.y + item.geometry.h - container_scrollbar_width,
				w = item.geometry.w, h = container_scrollbar_width }
		else
			scrollbar.geometry = {
				x = item.geometry.x + item.geometry.w - container_scrollbar_width,
				y = item.geometry.y,
				w = container_scrollbar_width, h = item.geometry.h }
		end
		fs = fs..scrollbar:render()
	end

	return fs
end

-- CONTAINERS WIDGETS
---------------------

nofs.register_widget("form", {
	is_root = true,
	orientation = 'vertical',
	handle_field_event = function(item, player_name, field)
			-- Only event corresponding to form is tab event
			if tonumber(field) then
				item:get_context().tab = tonumber(field)
			end
			item.form:update()
		end,
	lay_out = function(item)
			local margin = item:get_def_inherit('margin') or 0
			lay_out_box(item)
			item.geometry = {
				x = margin,
				y = margin,
				h = item.geometry.h + margin*2;
				w = item.geometry.w + margin*2;
			}
		end,
	render = function(item)
			local extra = ""
			if (default) then
				extra = default.gui_bg..default.gui_bg_img..default.gui_slots
			end

			-- Tab management
			if item.tabs and #item.tabs > 0 then
				local tabs = {}
				for _, tab in ipairs(item.tabs) do
					tabs[#tabs+1] = tab:get_attribute('label')
				end

				extra = extra..string.format('tabheader[0,0;%s;%s;%s;false;true]',
					item.id, table.concat(tabs, ','), item:get_context().tab or 1)
			end

			return nofs.fs_element_string('size', item.geometry)
				..extra..render_container(item)
		end,
})

nofs.register_widget("vbox", {
	orientation = 'vertical',
	lay_out = lay_out_box,
	render = render_container,
})

nofs.register_widget("hbox", {
	orientation = 'horizontal',
	lay_out = lay_out_box,
	render = render_container,
})

--- Tabs
-- Attributes :
--	- Label
nofs.register_widget("tab", {
	parent_type = 'form',
	overlapping = true,
	orientation = 'vertical',
	init = function(item)
			item.parent.tabs = item.parent.tabs or {}
			item.parent.tabs[#item.parent.tabs+1] = item
		end,
	lay_out = lay_out_box,
	render = function(item)
		if item == item.parent.tabs[item.parent:get_context().tab or 1] then
			return render_container(item)
		else
			return ''
		end
	end,

})
--[[
-- Tables : two types:
-- grids
-- tables with fixed columns and rows, for variable listings. items stored in list.

-- grid: rows and columns are determined according to children. children are
-- lists of rows which are lists of items : { {}, {}, .. }, { {}, {}, ..}, ..
nofs.register_widget("grid", {
	size = function(item)
		local colsizes, rowsizes = {}, {}
		local colnum, rownum
		item.size = { x = 0, y = 0 }
		-- Size rows and columns
		rownum = 0
		for _, row in ipairs(item) do
			assert(row.def.type == 'gridrow',
				string.format('[nofs] grid items should only have gridrow children (got a "%s").',
					row.def.type))
			rownum = rownum + 1
			rowsizes[rownum] = 0
			colnum = 0
			for _, child in ipairs(row) do
				colnum = colnum + 1
				colsizes[colnum] = colsizes[colnum] or 0
				if child.size then
					colsizes[colnum] = math.max(colsizes[colnum], child.size.x)
					rowsizes[rownum] = math.max(rowsizes[rownum], child.size.y)
				end
			end
		end

		-- Place children
		local x, y
		y = 0
		rownum, y = 1, 0
		for _, row in ipairs(item) do
			colnum, x = 1, 0
			for _, child in ipairs(row) do
				child.pos = align_position(
					{ x=colsizes[colnum], y=rowsizes[rownum] },
					child.size, { x = x, y = 0 },
					row.def.halign or item.def.halign or "center",
					row.def.valign or item.def.valign or "middle")
				x = x + colsizes[colnum]
				colnum = colnum + 1
			end
			row.size = { x = x, y = rowsizes[rownum] }
			item.size.x = math.max(item.size.x, row.size.x)
			row.pos = { x = 0, y = y }
			y = y + rowsizes[rownum]
			rownum = rownum + 1
		end
		item.size.y = y
	end,
	render = render_container,
})

nofs.register_widget("gridrow", {
	parent_type = 'grid',
	exclusive_child_type = true,
	render = render_container,
} )
]]
