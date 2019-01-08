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

--[[ Some fields are added to def table :
	- ids (on root only)
	- id (on all elements)
	- widget (on all elements)
]]

local FormDef = {}
FormDef.__index = FormDef

function nofs.is_formdef(formdef)
	local meta = getmetatable(formdef)
	return meta and meta == FormDef
end

function nofs.new_formdef(def)
	return Formdef:new(def)
end

function FormDef:new(def)
	-- Collect IDs and check types
	local function type_and_id_check(parent, def, ids)
		-- Type validity
		assert(def.type, 'Item definition must have a type.')
		def.widget = nofs.get_widget(def.type)
		assert(def.widget, string.format('Widget type "%s" unknown.', def.type))
		assert(parent or def.widget.is_root == true,
			string.format('Item type "%s" can not be root.', def.type))
		if parent and def.widget.parent_type then
			assert(def.widget.parent_type == parent.type,
				string.format('Item type "%s" can have only "%s" parent no "%s" parent.',
					def.type, def.widget.parent_type, parent.type))
		end
		if parent and parent.widget.children_type then
			assert(def.widget.type == parent.widget.children_type,
				string.format('Item type "%s" can have only "%s" children and no "%s" child.',
					parent.type, def.widget.children_type, def.type))
		end
		-- ID validity
		if def.id then
			assert(type(def.id) == 'string', 'Identifiers must be strings.')
			assert(def.id ~= "quit", 'Cannot use "quit" as an item id, it is a reserved word.')
			assert(def.id:sub(1,4) ~= "key_", string.format(
				'"%s" is not a valid item id, item ids cannot start with "key_".',
				def.id))
			assert(def.id:match('^[A-Za-z0-9_:]+$'), string.format(
				'"%s" is not a valid item id, item ids can contain only letters, number and "_".',
				def.id))
			assert(not ids[def.id], string.format(
				'"%s" id already in use in this form.', def.id))
			ids[def.id] = def
		end

		for _, child in ipairs(def) do
			type_and_id_check(def, child, ids)
		end
	end

	-- Add missing IDs and set metatable
	local function add_missing_id(def, ids)
		if def.id == nil then
			local i = 1
			while ids[def.type..i] do i = i + 1 end
			def.id = def.type..i
			ids[def.id] = def
		end

		for _, child in ipairs(def) do
			add_missing_id(child, ids)
		end

		setmetatable(def, self)
	end

	formdef = table.copy(def)
	-- TODO: Is this gonna be used?
	formdef.ids = {}
	type_and_id_check(nil, def, formdef.ids)
	add_missing_id(def, formdef.ids)
	return formdef
end

FormDef:get_attribute(name)
	if self[name] then
		return self[name]
	-- TODO: Is this gonna be used?
	elseif self.widget.defaults and self.widget.defaults[name] then
		return self.widget.defaults[name]
	elseif self.parent then
		return self.parent:get_attribute(name)
	end
end

FormDef:get_instance_data(form)
	local dataset
	if self.data then
		if type(self.data) == "table" then
			dataset = table.copy(self.data)
		elseif type(def.data) == "function" then
			dataset = table.copy(self.data(form))
		else
			assert(false, "data must be a table or a function")
		end
	else
		dataset = {{}}
	end

	return dataset
end
