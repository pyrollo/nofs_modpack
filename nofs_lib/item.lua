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

function Item:new(form, def, data)
	assert(nofs.is_form(form), "First argument of Item:new should be a Form.")
	assert(type(def) == "table", "Item definition must be a table.")
	assert(type(def.type) == "string", "Item must have a type.")

	local widget = nofs.get_widget(def.type)
	assert(widget ~= nil, "Item type must be valid.")

	local item = {
		id = def.id,
		registered_id = false,
		form = form,
		def = def,
		data = data,
--		type = def.type,
		widget = widget,
		pos = { x = 0, y = 0 },
		size = { x = 0, y = 0 }
	}

	setmetatable(item, self)
	self.__index = self -- Can be moved outside ?
	return item
end

function Item:resize()
	if self.widget.size and type(self.widget.size) == 'function' then
		self.widget.size(self)
	elseif self.widget.size and type(self.widget.size) == 'table' then
		-- Default size -- TODO: Will this be really used ?
		self.size = {
			x = self.def.width or self.widget.size.x,
			y = self.def.height or self.widget.size.y,
		}
	else
		self.size = { x = self.def.width, y = self.def.height }
	end
end

function Item:render(offset)
	self.form:register_id(self)

	if self.widget.render and type(self.widget.render) == 'function' then
		return self.widget.render(self, offset)
	else
		return ''
	end
end

function Item:handle_field_event(field)
	if self.widget.handle_field_event and
		type(self.widget.handle_field_event) == 'function'
	then
		return self.widget.handle_field_event(self, field)
	end
end

function Item:have_an_id()
	if not self.id then
		self.id = self.form:get_unused_id(self.def.type)
		self.form:register_id(self)
	end
end

function Item:get_context()
	return self.form:get_context(self)
end

function nofs.is_item(item)
	local meta = getmetatable(item)
	return meta and meta == Item
end

function nofs.new_item(form, def, data)
	return Item:new(form, def, data)
end
