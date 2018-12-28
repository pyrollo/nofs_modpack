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

function Form:new(player_name, def, context)
	assert(type(def) == "table", "Form definition must be a table.")
	assert(player_name, "Player name must be specified.")
	check_types_and_ids(def)

	local form = {
		def = table.copy(def),
		ids = {},            -- Items by id
		item = {},           -- Root item and descendants.
		item_contexts = {},  -- Persistant item contexts
		form_context = {},   -- Global form context
		player_name = player_name,
		trigger_queues = { [1] = {}, [2] = {}, }
	}
	form.def.type = "form"

	if context then
		form.form_context = table.copy(context)
	end

	setmetatable(form, self)
	return form
end

function Form:get_unused_id(prefix)
	prefix = prefix or "other"
	assert(not nofs.is_system_key(prefix), "Prefix must not be a system key.")
	local i = 1
	while self.ids[prefix..i] do
		i = i + 1
	end
	return prefix..i
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

-- Priority in trigger execution, lower is first
local trigger_queues = { on_clicked = 2,	default = 1, }

function Form:trigger(item, name, ...)
	local index = trigger_queues[name] or trigger_queues.default
	if self.trigger_queues[index] == nil then
		self.trigger_queues[index] = {}
	end
	table.insert(self.trigger_queues[index],
		{ item = item, name = name, args = {...}})
end

function Form:run_triggers()
	for _, queue in ipairs(self.trigger_queues) do
		while #queue > 0 do
			local trigger = queue[#queue]
			queue[#queue] = nil
			trigger.item:call(trigger.name, unpack(trigger.args))
		end
	end
end

function Form:save()
	for _, item in pairs(self.ids) do
		item:call('save')
	end
end

function Form:set_node(pos)
	self.node_meta = minetest.get_meta(pos)
	self.node_pos = table.copy(pos)
end

function Form:get_meta(meta)
	local pos = meta:find(':')
	assert(pos, "Reference to meta should be a string like node:xxx or player:yyy.")
	local ctx, key = meta:sub(1,pos-1), meta:sub(pos+1)
	if ctx == 'player' then
		local player
		if self.player_name then
			player = minetest.get_player_by_name(self.player_name)
		end
		if player and player.get_meta then
			return player:get_meta():get(key)
		elseif player and player.get_attribute then
			return player:get_attribute(key)
		else
			return string.format('${%s}', key)
		end
	end
	if ctx == 'node' and self.node_meta then
		return self.node_meta.get(key)
	end
end

function Form:set_meta(meta, value)
	local pos = meta:find(':')
	assert(pos, "Reference to meta should be a string like node:xxx or player:yyy.")
	local ctx, key = meta:sub(1,pos-1), meta:sub(pos+1)
	if ctx == 'player' then
		local player = minetest.get_player_by_name(self.player_name)
		if player and player.get_meta then
			player:get_meta():set_string(key, value)
		elseif player and player.set_attribute then
			player:set_attribute(key, value)
		else
			minetest.log('warning', '[nofs] Tryed to set metadata on player but player not found.')
		end
	end
	if ctx == 'node' then
		if self.node_meta then
			self.node_meta.set_string(key, value)
		else
			minetest.log('warning', '[nofs] Tryed to set metadata on node but no node set.')
		end
	end
end

-- Ensure persistance of item contexts
function Form:get_context(item)
	if item then
		item:have_an_id()
		if not self.item_contexts[item.id] then
			self.item_contexts[item.id] = {}
		end
		return self.item_contexts[item.id]
	else
		return self.form_context
	end
end

function Form:build_items()
	local function create_children(parent, def)
		local item
		if def.data and parent then
			local dataset
			if type(def.data) == "table" then
				dataset = table.copy(def.data)
			elseif type(def.data) == "function" then
				dataset = table.copy(def.data(self))
			end
			assert(parent or (dataset and #dataset == 1),
				"Root form item must have exactly one instance")
			if not dataset or #dataset == 0 then
				-- TODO : Add a "no data" widget possibility
				return -- No data, no occurence at all
			end

			for _, data in ipairs(dataset) do
				item = nofs.new_item(parent, def)
				local context = item:get_context()
				context.data = data

				for _, childdef in ipairs(def) do
					create_children(item, childdef)
				end
			end
		else
			if def.data then
				minetest.log("warning", '"data" attribute ignored for root element')
			end
			if parent then
				item = nofs.new_item(parent, def)
			else
				item = nofs.new_item(self, def)
				self.item = item
			end
			for _, childdef in ipairs(def) do
				create_children(item, childdef)
			end
		end
	end

	-- Empty ids
	self.ids = {}
	-- Instance creation
	create_children(nil, self.def)
end

function Form:render()
	local function recursive_size(item)
		-- first, size children (if any)
		for _, child in ipairs(item) do
			recursive_size(child)
		end
		item:size()
	end

	self:build_items()
	recursive_size(self.item)
	return self.item:render({ x = 0, y = 0 })
end

function Form:update()
	self.updated = true
end

function Form:receive(fields)
	local suspicious = false
	for key, value in pairs(fields) do
		local item = self.ids[key]
		if not nofs.is_system_key(key) and not item then
			minetest.log('warning',
				string.format('[nofs] Unwanted field "%s" for form "%s".',
					key, self.item.id))
			suspicious = true
		end
	end
	if suspicious then
		minetest.log('warning',
			string.format('[nofs] Suspicious formspec data recieved from player "%s".',
				self.player_name))
	end

	-- Field events
	for id, item in pairs(self.ids) do
		if fields[id] then
			item:handle_field_event(self.player_name, fields[id])
		end
	end

	self:run_triggers()

	if fields.quit == "true" then
		-- TODO: Trigger on_close event
		self:close()
	elseif self.updated then
		self.updated = nil
		self:refresh()
	end
end

function Form:show()
	-- Kind of random name -- Increases security ?
	self.name = self.name or string.format('nofs:'..minetest.get_us_time())
	nofs.get_form_stack(self.player_name):push(self)
	minetest.show_formspec(self.player_name, self.name, self:render())
end

function Form:refresh()
	local form = nofs.get_form_stack(self.player_name):top()
	if self ~= form then
		minetest.log("warning", sting.format(
			'[nofs] Form:refresh called while form not on top for player "%s".',
			self.player_name))
	else
		minetest.show_formspec(self.player_name, self.id, self:render())
	end
end

function Form:close()
	local stack = nofs.get_form_stack(self.player_name)
	if self ~= stack:top() then
		minetest.log("warning", sting.format(
			'[nofs] Form:close called while form not on top for player "%s".',
			self.player_name))
		return
	end

	stack:pop()
	if stack:top() then
		stack:top():refresh()
	else
		minetest.close_formspec(self.player_name, '')
	end
end

-- API functions
-- =============

function nofs.is_form(form)
	local meta = getmetatable(form)
	return meta and meta == Form
end

function nofs.show_form(player_name, def, context)
	local form = Form:new(player_name, def, context)
	nofs:get_form_stack(player_name).push(form)
	form:show()
end
