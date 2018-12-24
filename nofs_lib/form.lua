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

--------------------------------------------------------------------------------
-- Functions

local function check_types_and_ids(def, ids)
	if ids ~= nil then
		assert(def.type, 'Item definition must have a type.')
		assert(def.type ~= 'form', 'Only root item can be of type "form".')
		local widget = nofs.get_widget(def.type)
		assert(widget, 'Widget type "'..def.type..'" unknown.')
	else
		-- Dont check root type, it's always "form"
		ids = {}
	end

	if def.id then
		assert(ids[def.id] == nil,
			'Id "'..def.id..'" already used in the same form.')
		ids[def.id] = def
	end

	for _, child in ipairs(def) do
		check_types_and_ids(child, ids)
	end
end

--------------------------------------------------------------------------------
-- Form class

-- TODO: Checks :
-- item.def.max_items integer > 1
-- item.def.id should not start with '.' (reserved) ?

local Form = {}
Form.__index = Form

function Form:new(player_name, def)
	assert(type(def) == "table", "Form definition must be a table.")
	assert(player_name, "Player name must be specified.")
	check_types_and_ids(def)

	local form = {
		def = table.copy(def),
		instance = {},
		ids = {},
		item_contexts = {},
		context = { player_name = player_name },
		data = {}, -- TODO:Should be removed and replaced by other means
	}
	form.def.type = "form"

	setmetatable(form, self)
	return form
end

function Form:get_unused_id(prefix)
	local i = 1
	while self.ids[(prefix or "other")..i] do
		i = i + 1
	end
	return (prefix or "other")..i
end

function Form:register_id(item)
	if item.id and not item.registered_id then
		assert(self.ids[item.id] == nil,
			'Id "'..item.id..'" already used in the same form.')
		self.ids[item.id] = item
		item.registered_id = true
	end
end

function Form:get_element_by_id(id)
	return self.ids[id]
end

function Form:trigger_items(name, ...)
	for _, item in pairs(self.ids) do
		item:trigger(name, ...)
	end
end

function Form:save()
	self:trigger_items('save')
end

function Form:set_node(pos)
	self.context.node_meta = minetest.get_meta(pos)
	self.context.node_pos = table.copy(pos)
end

function Form:get_meta(meta)
	local pos = meta:find(':')
	assert(pos, "Reference to meta should be a string like node:xxx or player:yyy.")
	local ctx, key = meta:sub(1,pos-1), meta:sub(pos+1)
	if ctx == 'player' then
		local player
		if self.context.player_name then
			player = minetest.get_player_by_name(self.context.player_name)
		end
		if player and player.get_meta then
			return player:get_meta():get(key)
		elseif player and player.get_attribute then
			return player:get_attribute(key)
		else
			return string.format('${%s}', key)
		end
	end
	if ctx == 'node' and self.context.node_meta then
		return self.context.node_meta.get(key)
	end
end

function Form:set_meta(meta, value)
	local pos = meta:find(':')
	assert(pos, "Reference to meta should be a string like node:xxx or player:yyy.")
	local ctx, key = meta:sub(1,pos-1), meta:sub(pos+1)
	if ctx == 'player' then
		local player = minetest.get_player_by_name(self.context.player_name)
		if player and player.get_meta then
			player:get_meta():set_string(key, value)
		elseif player and player.set_attribute then
			player:set_attribute(key, value)
		else
			minetest.log('warning', '[nofs] Tryed to set metadata on player but player not found.')
		end
	end
	if ctx == 'node' then
		if self.context.node_meta then
			self.context.node_meta.set_string(key, value)
		else
			minetest.log('warning', '[nofs] Tryed to set metadata on node but no node set.')
		end
	end
end

-- Ensure persistance of item contexts
function Form:get_context(item)
	item:have_an_id()
	if not self.item_contexts[item.id] then
		self.item_contexts[item.id] = {}
	end
	return self.item_contexts[item.id]
end

function Form:build_items()
	local function build_items(def, data)
		local item = nofs.new_item(self, def, data)
		for _, childdef in ipairs(def) do
			if childdef.data then
				if data[childdef.data] and type(data[childdef.data]) == "table" then
					-- Data has children, multiple instances
					if #data[childdef.data] then
						for _, childdata in ipairs(data[childdef.data]) do
							item[#item+1] = build_items(childdef, childdata)
						end
					else
						-- cas d'un enfant avec un data={} ne contenant que des champs
						-- A vérifier l'utilité
						item[#item+1] = build_items(childdef, data[childdef.data])
					end
				else
					-- Cas habituel d'un enfant adressant directement un champ des data
					item[#item+1] = build_items(childdef, data)
				end
			else
				-- Cas d'un enfant sans data
				item[#item+1] = build_items(childdef, data)
			end
		end
		return item
	end

	-- Empty ids
	self.ids = {}
	-- Instance creation
	self.item = build_items(self.def, self.data)
end

function Form:render()
	local function size_items(item)
		-- first, size children (if any)
		for _, child in ipairs(item) do
			size_items(child)
		end
		item:resize()
	end

	self:build_items()

	size_items(self.item)

	return self.item:render({ x = 0, y = 0 })
end

function Form:update()
	self.updated = true
end

function nofs.is_form(form)
	local meta = getmetatable(form)
	return meta and meta == Form
end

function nofs.new_form(player_name, def)
	return Form:new(player_name, def)
end
