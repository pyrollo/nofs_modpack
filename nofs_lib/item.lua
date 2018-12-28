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

Item = {}
Item.__index = Item

function Item:new(parent, def)
	assert(type(def) == "table", 'Item definition must be a table.')
	assert(type(def.type) == "string", 'Item must have a type.')
	assert(not nofs.is_system_key(def.id or ""),
		string.format('Cannot use "%s" as id, it is a reserved word.', def.id))
	local widget = nofs.get_widget(def.type)
	assert(widget ~= nil, 'Item type must be valid.')
	assert(nofs.is_item(parent) or nofs.is_form(parent),
		'First argument of Item:new should be a Form or an Item.')


	local item = {
		id = def.id,
		registered_id = false,
		parent = nofs.is_item(parent) and parent or nil,
		form = nofs.is_form(parent) and parent or parent.form,
		def = def,
		widget = widget,
		geometry = { x = 0, y = 0, w = 0, h = 0 },
	}
	setmetatable(item, self)

	if item.parent then
		item.parent[#item.parent + 1] = item
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
	if self.widget[name] and type(self.widget[name]) == 'function' then
		return self.widget[name](self, ...)
	end
end

-- Enqueue trigger in form trigger queue
function Item:trigger(name, ...)
	self.form:trigger(self, name, ...)
end

function Item:handle_field_event(player_name, field)
	return self:call('handle_field_event', player_name, field)
end

function Item:have_an_id()
	if not self.id then
		self.id = self.form:get_unused_id(self.def.type)
	end
	if not self.registered_id then
		self.form:register_id(self)
	end
end

function Item:get_context()
	return self.form:get_context(self)
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

function Item:size()
	self.geometry.w = self.def.width or self.widget.width
	self.geometry.h = self.def.height or self.widget.height
	if self.widget.size and type(self.widget.size) == 'function' then
		self.widget.size(self)
	end
end

function Item:render(offset)
	self.form:register_id(self)
	-- Even "render" is overrideable
	local fs = self:call('render', offset) or ''
	if self:get_attribute('visible') == false then
		return ''
	else
		return fs
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

function nofs.new_item(form, def, data)
	return Item:new(form, def, data)
end
