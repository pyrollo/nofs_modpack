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

local Item = {}
Item.__index = Item

function Item:new(parent, def)
	local form

	-- Type checks
	assert(type(def) == "table", 'Item definition must be a table.')
	assert(type(def.type) == "string", 'I_utem must have a type.')
	local widget = nofs.get_widget(def.type)
		assert(widget ~= nil, 'Item type must be valid.')

	-- Parent check : Should be an Item or a Form for widgets with is_root=true
	if widget.is_root then
		assert(nofs.is_form(parent), string.format(
			'Parent of a "%s" item must be a Form object.', def.type))
		form = parent
		parent = nil
	else
		assert(nofs.is_item(parent), string.format(
			'Parent of a "%s" item must be an Item object.', def.type))
		form = parent.form
	end

	if widget.parent_type and not widget.is_root then
		assert(parent.def.type == widget.parent_type, string.format(
			'"%s" element can not have a "%s" parent.', def.type, parent.def.type))
	end

	-- Id checks
	if def.id then
		assert(def.id ~= "quit", 'Cannot use "quit" as an item id, it is a reserved word.')
		assert(def.id:sub(1,4) ~= "key_", string.format(
			'"%s" is not a valid item id, item ids cannot start with "key_".',
			def.id))
		assert(def.id:match('^[A-Za-z0-9_:]+$'), string.format(
			'"%s" is not a valid item id, item ids can contain only letters, number and "_".',
			def.id))
	end

	-- Instanciation
	local item = {
		id = def.id,
		registered_id = false,
		parent = parent,
		form = form,
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

function Item:handle_field_event(player_name, field, subid)
	return self:call('handle_field_event', player_name, field, subid)
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

function Item:lay_out()
	self.geometry.w = self.def.width or self.widget.width
	self.geometry.h = self.def.height or self.widget.height
	if self.widget.lay_out and type(self.widget.lay_out) == 'function' then
		self.widget.lay_out(self)
	end
	if self.geometry.w and self.geometry.h then
		return true
	else
		minetest.log("error", string.format("[nofs] %s%s element is missing %s.",
		self.def.type, (self.id and ' ('..self.id..')' or ''),
		(self.geometry.w and "" or "width")..(self.geometry.h and "" or
				(self.geometry.w and "height" or " and height"))))
		return false
	end
end

function Item:render(offset)
	if self:get_attribute('visible') == false then
		return ''
	else
		return self:call('render') or ''
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
