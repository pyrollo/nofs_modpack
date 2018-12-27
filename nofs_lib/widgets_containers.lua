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

local function align_position(container_size, item_size, offset, halign, valign)
	local x, y
	if valign == 'top' then
		y = offset.y
	elseif valign == 'bottom' then
		y = offset.y + container_size.y - item_size.y
	else
		y = offset.y + container_size.y / 2 - item_size.y / 2
	end

	if halign == 'left' then
		x = offset.x
	elseif halign == 'right' then
		x = offset.x + container_size.x - item_size.x
	else
		x = offset.x + container_size.x / 2 - item_size.x / 2
	end

	return { x=x, y=y }
end


local container_scrollbar_width = 0.5

-- Sizing vbox and hbox and places child items inside
local function size_box(item)
	local pos1, pos2, size1, size2
	-- Process vbox and hbox the same way, just inverting coordinates
	if item.widget.orientation == 'horizontal' then
		pos1, pos2, size1, size2 = 'x', 'y', 'w', 'h'
	else
		pos1, pos2, size1, size2 = 'y', 'x', 'h', 'w'
	end

	local dim1, dim2 = 0, 0 -- TODO:MARGIN

	-- dim2 = max child size
	for _, child in ipairs(item) do
		if child.geometry[size2] > dim2 then
			dim2 = child.geometry[size2]
		end
	end

	local start_index = item:get_context().start_index or 1

	-- Positionning and dim1 (=sum child sizes)
	for index, child in ipairs(item) do
		if not item.def.max_items or
			index >= start_index and index < start_index + item.def.max_items
		then
			align_position(
				child.geometry,
				{ [pos1] = dim1, [pos2] = 0,
					[size1] = child.geometry[size1], [size2] = dim2 },
				item.def.halign or "center", item.def.valign or "middle")

			dim1 = dim1 + child.geometry[size1] -- TODO:Spacing
		end
	end

  -- Improvements needed for overflow managing (type, positionning, visibility)
	if item.def.overflow and item.def.overflow == 'scrollbar' then
		dim2 = dim2 + container_scrollbar_width
	end

	-- Finally set box size according to previous findings
	item.geometry[size1] = dim1
	item.geometry[size2] = dim2
end

-- Containers generic rendering
--
local function render_container(item, offset)

	local inneroffset = {
		x = offset.x + item.geometry.x,
		y = offset.y + item.geometry.y
	}

	local start_index = item:get_context().start_index or 1

	local overflow = false

	local fs = ""
	for index, child in ipairs(item) do
		if item.def.max_items and
			(index < start_index or index >= start_index + item.def.max_items)
		then
			overflow = true
		else
			fs = fs..child:render(inneroffset)
		end
	end

	if overflow --and item.def.overflow and item.def.overflow == 'scrollbar'
	then
		-- Box must have an ID to be addressed
		item:have_an_id()

		local scrollbar = nofs.new_item(item.form, {
				type = 'scrollbar',
				orientation = item.widget.orientation,
				connected_to = item.id,
			}, {}) -- TODO :DATA?? -- To be linked to item? Context?

		if item.def.orientation == 'horizontal' then
			scrollbar.geometry = {
				x = 0, y = item.size.y - container_scrollbar_width,
				w = item.size.x, h = container_scrollbar_width }
		else
			scrollbar.geometry = {
				x = item.size.x - container_scrollbar_width, y = 0,
				w = container_scrollbar_width, h = item.size.y }
		end
		fs = fs..scrollbar:render(inneroffset)
	end

	return fs
end

-- CONTAINERS WIDGETS
---------------------

nofs.register_widget("form", {
	orientation = 'vertical',
	size = size_box,
	render = function(item, offset)
		return nofs.fs_element_string('size', item.geometry)
			..render_container(item, offset or { x=0, y=0 }))
	end,
})

nofs.register_widget("vbox", {
	orientation = 'vertical',
	size = size_box,
	render = render_container,
})

nofs.register_widget("hbox", {
	orientation = 'horizontal',
	size = size_box,
	render = render_container,
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

nofs.register_widget("gridrow", { render = render_container } )
]]
