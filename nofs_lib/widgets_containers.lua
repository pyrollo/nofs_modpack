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

local function align_position(container_size, element_size, offset, halign, valign)
	local x, y
	if valign == 'top' then
		y = offset.y
	elseif valign == 'bottom' then
		y = offset.y + container_size.y - element_size.y
	else
		y = offset.y + container_size.y / 2 - element_size.y / 2
	end

	if halign == 'left' then
		x = offset.x
	elseif halign == 'right' then
		x = offset.x + container_size.x - element_size.x
	else
		x = offset.x + container_size.x / 2 - element_size.x / 2
	end

	return { x=x, y=y }
end


-- TODO:Remove, this is temporary
local start_index = 1

local container_scrollbar_width = 0.5

-- Manque context:index
-- Sizing vbox and hbox and places child elements inside
local function size_box(element)
	local main, other
	local pos = 0 -- TODO:MARGIN
	local size = 0

	-- Process vbox and hbox the same way, just inverting coordinates
	if element.widget.orientation == 'horizontal' then
		main = 'x' other = 'y'
	else
		main = 'y' other = 'x'
	end

	-- Max other size
	for _, child in ipairs(element) do
		if child.size[other] > size then
			size = child.size[other]
		end
	end

	-- Positionning
	for index, child in ipairs(element) do
		if not element.def.max_items or
			index >= start_index and index < start_index + element.def.max_items
		then
			child.pos = align_position(
				{ [main] = child.size[main], [other] = size },
				child.size, { [main] = pos, [other] = 0 },
				element.def.halign or "center", element.def.valign or "middle")

			pos = pos + child.size[main] -- TODO:Spacing

		-- TODO: This is center, add left & right
			child.pos[other] =
				( size - child.size[other] ) / 2
		end
	end

  -- Improvements needed for overflow managing (type, positionning, visibility)
	if element.def.overflow and element.def.overflow == 'scrollbar' then
		size = size + container_scrollbar_width
	end

	element.size = { [main] = pos, [other] = size }
end

-- Containers generic rendering
--
local function render_container(form, element, offset)

	local inneroffset = {
		x = offset.x + element.pos.x,
		y = offset.y + element.pos.y
	}

	local overflow = false

	local fs = ""
	for index, child in ipairs(element) do
		if element.def.max_items and
			(index < start_index or index >= start_index + element.def.max_items)
		then
			overflow = true
		else
			fs = fs..form:render_element(child, inneroffset)
		end
	end

	if overflow --and element.def.overflow and element.def.overflow == 'scrollbar'
	then
		local scrollbar = {
			type = 'scrollbar',
			def = {
				type = 'scrollbar',
				orientation = element.widget.orientation,
			},
			widget = nofs.get_widget('scrollbar'),
		}
		if element.def.orientation == 'horizontal' then
			scrollbar.pos = { x = 0, y = element.size.y - container_scrollbar_width }
			scrollbar.size = { x = element.size.x, y = container_scrollbar_width }
		else
			scrollbar.pos = { x = element.size.x - container_scrollbar_width, y = 0 }
			scrollbar.size = { x = container_scrollbar_width, y = element.size.y, }
		end
		fs = fs..form:render_element(scrollbar, offset)
	end

	return fs
end

-- CONTAINERS WIDGETS
---------------------

nofs.register_widget("form", {
	orientation = 'vertical',
	size = size_box,
	render = function(form, element, offset)
		return string.format("size[%g,%g]%s", element.size.x, element.size.y,
			render_container(form, element, offset or { x=0, y=0 }))
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

-- Tables : two types:
-- grids
-- tables with fixed columns and rows, for variable listings. items stored in list.

-- grid: rows and columns are determined according to children. children are
-- lists of rows which are lists of elements : { {}, {}, .. }, { {}, {}, ..}, ..
nofs.register_widget("grid", {
	size = function(element)
		local colsizes, rowsizes = {}, {}
		local colnum, rownum
		element.size = { x = 0, y = 0 }
		-- Size rows and columns
		rownum = 0
		for _, row in ipairs(element) do
			assert(row.def.type == 'gridrow',
				string.format('[nofs] grid elements should only have gridrow children (got a "%s").',
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
		for _, row in ipairs(element) do
			colnum, x = 1, 0
			for _, child in ipairs(row) do
				child.pos = align_position(
					{ x=colsizes[colnum], y=rowsizes[rownum] },
					child.size, { x = x, y = 0 },
					row.def.halign or element.def.halign or "center",
					row.def.valign or element.def.valign or "middle")
				x = x + colsizes[colnum]
				colnum = colnum + 1
			end
			row.size = { x = x, y = rowsizes[rownum] }
			element.size.x = math.max(element.size.x, row.size.x)
			row.pos = { x = 0, y = y }
			y = y + rowsizes[rownum]
			rownum = rownum + 1
		end
		element.size.y = y
	end,
	render = render_container,
})

nofs.register_widget("gridrow", { render = render_container } )
