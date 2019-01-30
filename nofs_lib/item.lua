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

-- Item : an item instance with a geometry and a context

local Item = {}
Item.__index = Item

function nofs.is_item(item)
	local meta = getmetatable(item)
	return meta and meta == Item
end

function Item:new(form, parent, id, def)

	-- Type checks
	assert(type(def) == "table", 'Item definition must be a table.')
	assert(type(def.widget) == "table", 'Definition widget must be a table.')
	assert(nofs.is_form(form), 'Form must be a Form object')
  if parent then
		assert(nofs.is_item(parent), 'Parent must be an Item object')
	end

	-- Instanciation
	local item = {
		id = id,
		form = form,
		def = def,
		geometry = { x = 0, y = 0, w = 0, h = 0 },
	}
	setmetatable(item, self)

	if parent then
		parent[#parent + 1] = item
		item.parent = parent
	end

	-- TODO: Use a Form method that checks for item id unicity ?
	form.ids[id] = item
	if def.widget.componants then
		for _, componant in ipairs(def.widget.componants) do
			form.ids[id..'.'..componant] = item
		end
	end

	item:call('init')

	return item
end

-- Method that launches functions :)
function Item:call(name, ...)
	-- First try def specific function (override)
	if self.def[name] and type(self.def[name]) == 'function' then
		return self.def[name](self, ...)
	end

	-- Then try widget generic function
	if self.def.widget[name] and type(self.def.widget[name]) == 'function' then
		return self.def.widget[name](self, ...)
	end
end

-- Enqueue trigger in form trigger queue
function Item:trigger(name, ...)
	self.form:queue_trigger(self, name, ...)
end

function Item:handle_field_event(fieldvalue, fieldname)
	return self:call('handle_field_event', fieldvalue, fieldname)
end


function Item:lay_out()
	self.geometry.w = self.def.width or self.def.widget.width
	self.geometry.h = self.def.height or self.def.widget.height
	if self.def.widget.lay_out and type(self.def.widget.lay_out) == 'function'
	then
		self.def.widget.lay_out(self)
	end
	if self.geometry.w and self.geometry.h then
		return true
	else
		minetest.log("error", string.format("[nofs] %s element%s is missing %s.",
		self.def.type, (self.def.id and ' ('..self.def.id..')' or ''),
		(self.geometry.w and "" or "width")..(self.geometry.h and "" or
				(self.geometry.w and "height" or " and height"))))
		return false
	end
end

function Item:render()
	if self:get_attribute('visible') == false then
		return ''
	else
		return self:call('render') or ''
	end
end

function Item:get_context(key)
	local context = self.form:get_context(self)
	if key and context then
		return context[key]
	else
		return context
	end
end

function Item:set_context(key, value)
	local context = self.form:get_context(self)
	context[key] = value
end

function Item:get_data(key)
	local context = self:get_context()
	if context.data and context.data[key] then
		return context.data[key]
	end
	if self.parent then
		return self.parent:get_data(key)
	end
end

-- Attribute : can be inherited and / or dynamic
function Item:get_attribute(name)
	local dynamic = self.def.widget.dynamic
		and self.def.widget.dynamic[name] ~= nil
	if dynamic then
		local context = self:get_context()
		if context and context[name] then
			return context[name]
		end
	end
	if self.def[name] then
		return self.def[name]
	end
	if self.def.widget.heritable and self.def.widget.heritable[name] ~= nil then
		if parent then
			return parent:get_attribute(name) or self.def.widget.heritable[name]
		else
			return self.def.widget.heritable[name]
		end
	end
	if dynamic then
		return self.def.widget.dynamic[name]
	end
end

function nofs.new_item(form, parent, id, def)
	return Item:new(form, parent, id, def)
end
