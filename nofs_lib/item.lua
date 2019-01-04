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

function Item:new(form, parent, def, instance_id)
	local form

	-- Type checks
	assert(type(def) == "table", 'Item definition must be a table.')
	assert(type(def.widget) == "string", 'Definition must have a widget.')

	-- Instanciation
	local item = {
--		id = def.id,
		instance_id = instance_id or '',
		form = form,
		def = def,
		context = {},
--		widget = def.widget,
		geometry = { x = 0, y = 0, w = 0, h = 0 },
	}
	setmetatable(item, self)

	if parent then
		parent[#parent + 1] = item
		item.parent = parent
	end

	item:call('init')

	return item
end

function Item:get_id()
	return self.def.id..self.instance_id
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
	self.form:trigger(self, name, ...)
end

function Item:handle_field_event(fieldvalue, fieldname)
	return self:call('handle_field_event', fieldvalue, fieldname)
end

function Item:set_context(data)
	for key, value in data
		self.context[key] = value
	end
end

function Item:lay_out()
	self.geometry.w = self.def.width or self.widget.width
	self.geometry.h = self.def.height or self.widget.height
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


--------------------------------------------------------------------------------
-- TODO:A REVOIR


function Item:get_context()
	return self.context
end

-- TODO:name ? get_contextual_attribute?
function Item:get_attribute(name)
	if self.id then
		local context = self.form.item_contexts[self.id]
		if context and context[name] then
			return context[name]
		end
	end
	return self.def[name]
end

-- TODO:name ?
function Item:get_def_inherit(name)
	if self.def[name] then
		return self.def[name]
	elseif self.widget.defaults and self.widget.defaults[name] then
		return self.widget.defaults[name]
	elseif self.parent then
		return self.parent:get_def_inherit(name)
	end
end



function Item:get_value()
	local context = self.form:get_context(self)
	if context then
		return context.value
	end
end

function nofs.is_item(item)
	local meta = getmetatable(item)
	return meta and meta == Item
end

function nofs.new_item(form, def)
	return Item:new(form, def)
end
