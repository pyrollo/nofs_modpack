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

-- This file is about formspec funky placement corrections
-- Render all element using the same and consistent coordiante system

-- Base size choosen to make 'spacing' = { x = 1, y = 1 }
local base_size = { x = 4/5, y = 13/15 }

-- Same computation as in guiFormSpecMenu.cpp
local imgsize = { x = base_size.x, y = base_size.y }
local spacing = { x = base_size.x*5/4, y = base_size.y*15/13 }
local padding = { x = base_size.x*3/8, y = base_size.y*3/8 }
local btn_height = base_size.y * 15/13*0.35

-- AbsoluteRect.UpperLeftCorner seems to be 0,0. So it is ommited in computation
-- (image element)

nofs.fs_field_height = btn_height * 2

-- Geometry computation uses the inverse function of the one used in
-- guiFormSpecMenu.cpp, divided by spacing. Aim is to have a consistent
-- coordinate system.

local fsgeometry = {
	size = function(geometry)
			return string.format("%g,%g",
				(geometry.w - imgsize.x - padding.x*2 ) / spacing.x + 1,
				(geometry.h - imgsize.y - padding.y*2 - btn_height*2/3) / spacing.y + 1)
		end,
-- list : see specific bellow
	image = function(geometry)
			return string.format("%g,%g;%g,%g",
				geometry.x - padding.x/spacing.x,
				geometry.y - padding.y/spacing.y,
				geometry.w * spacing.x / imgsize.x,
				geometry.h * spacing.y / imgsize.y)
		end,
	pwdfield = function(geometry) -- Same as field
			return string.format("%g,%g;%g,0",
				geometry.x,
				geometry.y + btn_height*spacing.y,
				geometry.w + 1 - imgsize.x/spacing.x)
		end,
	field = function(geometry)
			return string.format("%g,%g;%g,0",
				geometry.x,
				geometry.y + btn_height*spacing.y,
				geometry.w + 1 - imgsize.x/spacing.x)
		end,
	textarea = function(geometry)
			return string.format("%g,%g;%g,%g",
				geometry.x, -- It seems that for text_area, padding has been forgotten
				geometry.y - btn_height/spacing.y,
				geometry.w - imgsize.x + 1,
				(geometry.h + spacing.y) / imgsize.y - 1)
		end,
	button = function(geometry) -- Same as field
			return string.format("%g,%g;%g,0",
				geometry.x,
				geometry.y + btn_height*spacing.y,
				geometry.w + 1 - imgsize.x/spacing.x)
		end,
	image_button = function(geometry)
			return string.format("%g,%g;%g,%g",
				geometry.x - padding.x/spacing.x,
				geometry.y - padding.y/spacing.y,
				geometry.w - imgsize.x + 1,
				geometry.h - imgsize.y + 1)
		end,
	image_button_exit = function(geometry) -- Same as image_button
			return string.format("%g,%g;%g,%g",
				geometry.x - padding.x/spacing.x,
				geometry.y - padding.y/spacing.y,
				geometry.w - imgsize.x + 1,
				geometry.h - imgsize.y + 1)
		end,
	box = function(geometry)
			return string.format("%g,%g;%g,%g",
				geometry.x - padding.x/spacing.x,
				geometry.y - padding.y/spacing.y,
				geometry.w,
				geometry.h)
		end,
	checkbox = function(geometry) --???
			return string.format("%g,%g;%g,%g",
				geometry.x - padding.x/spacing.x,
				geometry.y - padding.y/spacing.y,
				geometry.w,
				geometry.h)
		end,
	scrollbar = function(geometry) -- Same as box
			return string.format("%g,%g;%g,%g",
				geometry.x - padding.x/spacing.x,
				geometry.y - padding.y/spacing.y,
				geometry.w,
				geometry.h)
		end,
}

local fsspecific = {
	list = function(geometry, location, list_name, starting_index)
			return string.format("list[%s;%s;%g,%g;%g,%g;%s]",
				location, list_name,
				geometry.x, geometry.y, geometry.w, geometry.h,
				starting_index or 1)
		end,
}

function nofs.fs_element_string(type, geometry, ...)
	if fsspecific[type] then
		return fsspecific[type](geometry, ...)
	else
		assert (fsgeometry[type], string.format('Unknown element type "%s".', type))
		return string.format("%s[%s;%s]", type, fsgeometry[type](geometry),
			table.concat({...}, ";"))
	end
end
