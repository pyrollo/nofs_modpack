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

local widgets

-- Helpers
local function message(message)
    minetest.log('warning', '['..nofs.name..'] '..message)
end

-- Forward declarations
--local set_defs_and_collect_ids, add_missing_ids,
local size_element, render_element


-- Standard offset position and size
local function fspos(buffer, offset)
  local widgetoffset = widgets[buffer.def.type].offset
  if widgetoffset then
    return string.format("%g,%g",
      buffer.pos.x + offset.x + widgetoffset.x,
      buffer.pos.y + offset.y + widgetoffset.y)
  else
    return string.format("%g,%g",
      buffer.pos.x + offset.x, buffer.pos.y + offset.y)
  end
end

local function fspossize(buffer, offset)
  local widgetoffset = widgets[buffer.def.type].offset
  if widgetoffset then
    return string.format("%g,%g;%g,%g",
      buffer.pos.x + offset.x + widgetoffset.x,
      buffer.pos.y + offset.y + widgetoffset.y,
      buffer.size.x, buffer.size.y)
  else
    return string.format("%g,%g;%g,%g",
      buffer.pos.x + offset.x, buffer.pos.y + offset.y,
      buffer.size.x, buffer.size.y)
  end
end

-- Sizing vbox and hbox
--
local function size_box(buffer, boxtype)
	buffer.size = { 0, 0 }

	local main, other

	-- Process vbox and hbox the same way, just inverting coordinates
	if boxtype == 'h' then
		main = 'x' other = 'y'
	else
		main = 'y' other = 'x'
	end

	local pos = 0 -- TODO:MARGIN
	local size = 0

	-- Main positionning and other size
	for index, child in ipairs(buffer.children) do
		size_element(buffer.children[index])
		buffer.children[index].pos[main] = pos
		pos = pos + buffer.children[index].size[main] -- TODO:Spacing
		if buffer.children[index].size[other] > size then
			size = buffer.children[index].size[other]
		end
	end

	-- Size + margin*2

	-- Other positionning
	for index, child in ipairs(buffer.children) do
		-- TODO: This is center, add left & right
		buffer.children[index].pos[other] =
			( size - buffer.children[index].size[other] ) / 2
	end

	buffer.size[main] = pos
	buffer.size[other] = size
end

-- Containers generic rendering
--
local function render_container(buffer, offset)
	local inneroffset = {
    x = offset.x + buffer.pos.x,
    y = offset.y + buffer.pos.y
  }
	local fs = ""
	for index, child in ipairs(buffer.children) do
		fs = fs..render_element(child, inneroffset)
	end
	return fs
end

-- Widget definitions
--

widgets = {
	vbox = {
		sizing = function(buffer)
			size_box(buffer, 'v')
		end,
		rendering = render_container,
	},
	hbox = {
		sizing = function(buffer)
			size_box(buffer, 'h')
		end,
		rendering = render_container,
	},
	button = {
		needs_id = true,
		rendering = function(buffer, offset)
			-- Some warnings
			if buffer.def.item ~= nil then
				if buffer.def.image ~= nil then
				    message('WARNING: Button can\'t have "image" and "item" attributes at once. '..
				            'Ignoring "item" attribute.')
				end
				if buffer.def.exit == 'true' then
				    message('WARNING: Button can\'t have exit=true and item attributes at once. '..
				            'Ignoring exit=true attribute.')
				end
			end

			-- Now, render !
			if buffer.def.image then
				if buffer.def.exit == "true" then
          return string.format("image_button_exit[%s;%s;%s;%s]",
            fspossize(buffer, offset), buffer.def.image, buffer.id, buffer.def.label or "")
				else
          return string.format("image_button[%s;%s;%s;%s]",
            fspossize(buffer, offset), buffer.def.image, buffer.id, buffer.def.label or "")
				end
			elseif buffer.def.item then
				return string.format("item_image_button[%s;%s;%s;%s]",
        fspossize(buffer, offset), buffer.def.item, buffer.id, buffer.def.label or "")
			else
				if buffer.def.exit == "true" then
          return string.format("button_exit[%s;%s;%s]",
          fspossize(buffer, offset), buffer.id, buffer.def.label or "")
				else
          return string.format("button[%s;%s;%s]",
          fspossize(buffer, offset), buffer.id, buffer.def.label or "")
				end
			end
		end,
	},
	field = {
    needs_id = true,
    offset = { x = 0.3, y = 0.32 },
		rendering = function(buffer, offset)
			-- Some warnings
			if buffer.def.hidden == 'true' then
			    if buffer.def.default ~= nil then
				    message('WARNING: Hidden field can\'t have a default value. '..
				            'Ignoring "default" attribute.')
				end
			  -- TODO : Can't have bound variable neither
			end

			-- Render
			if buffer.def.hidden == 'true' then
				return string.format("pwdfield[%s;%s;%s]", fspossize(buffer, offset),
          buffer.id, (buffer.def.label or ""))
			else
				return string.format("field[%s;%s;%s;%s]", fspossize(buffer, offset),
          buffer.id, (buffer.def.label or ""), (buffer.def.default or ""))
			end
		end,
	},
	label = {
    offset = { x = 0, y = 0.2 },
		rendering = function(buffer, offset)
			if buffer.def.direction and buffer.def.direction == 'vertical' then
				return string.format("vertlabel[%s;%s]",
          fspos(buffer, offset), (buffer.def.label or ""))
			else
        return string.format("label[%s;%s]",
          fspos(buffer, offset), (buffer.def.label or ""))
			end
		end,
	},
  checkbox = {
    needs_id = true,
    rendering = function(buffer, offset)
      return string.format("checkbox[%s;%s;%s;%s]",
        fspos(buffer, offset), buffer.id, (buffer.def.label or ""),"true")
    end,
  },
  inventory = {
    rendering = function(buffer, offset)
      return string.format("list[%s;%s;%s;]%s",
        buffer.def.inventory or "current_player",
        buffer.def.list or "main",
        fspossize(buffer, offset),
        buffer.def.listring and "listring[]" or "")
    end,
  },
}

-- Form rendering
-- ==============
-- Pass 1 : Basic controls, add a def member pointing to definition, collect ids
-- Pass 2 : Add missing IDs
-- Pass 3 : Compute parent size from children sizes (pre-render)
-- Pass 4 : Place everything and render (render)

-- Pass 1 : Basic controls, add a def member pointing to definition, collect ids
--
local function set_defs_and_collect_ids(buffer, elements_by_id)
  local def = buffer.def
	assert(def.type, 'Element must have a type.')
	assert(widgets[def.type], 'Element type "'..def.type..'" unknown.')

	if def.id then
		assert(elements_by_id[def.id] == nil,
			'Id "'..def.id..'" already used in the same form.')
		buffer.id = def.id
		elements_by_id[def.id] = buffer
	end

  buffer.children = {}

  for index, child in ipairs(def) do
	 	buffer.children[index] = { def = child }
		set_defs_and_collect_ids(buffer.children[index], elements_by_id)
	end
end

-- Pass 2 : Add missing IDs
--
local function add_missing_ids(buffer, elements_by_id)
  local def = buffer.def
	if not buffer.id and widgets[def.type].needs_id then
		local i = 1
		while elements_by_id[def.type..i] do
			i = i + 1
		end
		buffer.id = def.type..i
		elements_by_id[buffer.id] = buffer
	end

	if buffer.children then
	 	for index, child in ipairs(buffer.children) do
			add_missing_ids(child, elements_by_id)
		end
	end
end

-- Pass 3 : Compute parent size from children sizes (pre-render)
--
size_element = function(buffer)
  local def = buffer.def
	buffer.pos = { x = 0, y = 0 }
	buffer.size = { x = 0, y = 0 }

	local widget = widgets[def.type]
	if widget.sizing then
		widget.sizing(buffer)
	else -- Default case for simple elements
		buffer.size = { x=def.width, y=def.height }
	end
end

-- Pass 4 : Place everything and render (render)
--
render_element = function(buffer, offset)
	local widget = widgets[buffer.def.type]
	if widget.rendering then
		return widget.rendering(buffer, offset)
	else
		return ""
	end
end

-- Entry point
function nofs.render_form(form)
	local buffer = { def = form, elements_by_id = {} }

	if not buffer.def.type then
		buffer.def.type = "vbox"
    end

	set_defs_and_collect_ids(buffer, buffer.elements_by_id)
	add_missing_ids(buffer, buffer.elements_by_id)
	size_element(buffer)
	local render = render_element(buffer, {x = 0, y = 0})
	return string.format("size[%g,%g]%s", buffer.size.x, buffer.size.y, render)
end
