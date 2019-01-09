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
-- Form class
--------------------------------------------------------------------------------

-- TODO: Checks :
-- item.def.max_items integer > 1

local Form = {}
Form.__index = Form

function nofs.is_form(form)
	local meta = getmetatable(form)
	return meta and meta == Form
end

-- TODO:Il faudrait séparer Form en Form et FormInstance. Form un objet a créer une fois, et FormInstance à créer par joueur

function Form:new(player_name, def, context)
	assert(type(def) == "table", "Form definition must be a table.")

	assert(player_name, "Player name must be specified.")

	local new = {
		def = nofs.new_formdef(def),
		ids = {},            -- Elements by id
		item = {},           -- Root item and descendants.
		item_contexts = {}	,  -- Persistant item contexts
		form_context = {},   -- Global form context
		player_name = player_name,
		trigger_queues = { [1] = {}, [2] = {}, }
	}
	setmetatable(new, self)

	new.def.type = new.def.type or "form"

	check_def(new.def)

	if context then -- TODO:A REVOIR
		new.form_context = table.copy(context)
	end

	return new
end

-- C'est ici qu'on peut vérifier le cas statique pour lequel on n'a pas le droit à
-- - data
-- - autre champs ?

function Form:build_instance()

	local function create_items(parent, def, instance_id)
		local dataset = def:get_instance_data(self)

		assert(parent or #dataset == 1,
			"Root form item must have exactly one instance")

		local id = def.id
		for index, data in ipairs(dataset) do
			local instance_id = instance_id or ''
			if #dataset > 1 then
				instance_id = instance_id.."."..index
			end

			-- TODO: Instance id management is a bit hacky
			def.id = id..instance_id
			local item = nofs.new_item(self, parent, def)

			-- If composite widget, register item several times
			if def.widget.componants then
				for _, componant in ipairs(def.widget.componants) do
					self.ids[def.id..'.'..componant] = item
				end
			else
				self.ids[def.id] = item
			end

			if parent == nil then
				self.item = item
			end

-- ICI CA NE VA PAS. Il y a un problème de parenté si on prend un contexte ancien + un context nouveau
-- Le lien de parenté devrait se faire par les ID toujours.

--[[
Pas de problème si les data ne changent pas. Si elle changent, on doit perdre le contexte associé.
Il faudrait dans ce cas avoir sauvé l'ancenne valeur.
On peut imaginer un form qui sauve tout le temps ou avant de récupérer les données.
On peut imaginer une valeur contextuelle indiquant qu'il faut sauvegarder.
On peut imaginer des champs avec "autosave"

Le contexte c'est :
- La valeur affichée (dépend des données, doit être sauvée)
- Le label affiché (dépend des données)
- L'index de départ (dépend du nombre de données, pourrait être recalculée)
- La position d'une scrollbar (dépend du nombre de données, pourrait être recalculée)

Sur le container comprenant des données, ajouter des méthodes fetch et save ?
]]

			if self.item_contexts[def.id] then
				item.context = self.item_contexts
			else
				self.item_contexts[def.id] = item.context
			end

			item:set_context(data, true)

			for _, childdef in ipairs(def) do
				create_items(item, childdef, instance_id)
			end
		end
		def.id = id
	end

	self.ids = {}
	create_items(nil, self.def, '')
end

function Form:render()
	local function recursive_lay_out(item)
		for _, child in ipairs(item) do
			if not recursive_lay_out(child) then
				return false
			end
		end
		return item:lay_out()
	end

	local function position(item, pos)
		item.geometry.x = item.geometry.x + pos.x
		item.geometry.y = item.geometry.y + pos.y
		for _, child in ipairs(item) do
			position(child, { x = item.geometry.x, y = item.geometry.y})
		end
	end

	self:build_instance()

	if recursive_lay_out(self.item) then
		position(self.item, { x = 0, y = 0 })
		return self.item:render()
	else
		return ''
	end
end

function Form:get_element_by_id(id)
	return self.ids[id]
end

-- Priority in trigger execution, lower is first
local trigger_queues = { on_clicked = 2,	default = 1, }

function Form:queue_trigger(item, name, ...)
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
function Form:get_context()
	return self.form_context
end

function Form:update()
	self.updated = true
end

function Form:receive(fields)
	local suspicious = false
	for key, value in pairs(fields) do
		if key ~= "quit" and key:sub(1,4) ~= "key_" then
			local item = self.ids[key]
			if not item or not item.def.widget.handle_field_event then
				minetest.log('warning',
					string.format('[nofs] Unwanted field "%s" for form "%s".',
						key, self.item:get_id()))
				suspicious = true
			end
		end
	end
	if suspicious then
		minetest.log('warning',
			string.format('[nofs] Suspicious formspec data recieved from player "%s".',
				self.player_name))
	end

	-- Field events
	for name, value in pairs(fields) do
		if self.ids[name] then
			self.ids[name]:handle_field_event(value, name)
		end
	end

	self:run_triggers()

	if fields.quit == "true" then
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
	print(self:render())

	minetest.show_formspec(self.player_name, self.name, self:render())
end

function Form:refresh()
	local form = nofs.get_form_stack(self.player_name):top()
	if self ~= form then
		minetest.log("warning", sting.format(
			'[nofs] Form:refresh called while form not on top for player "%s".',
			self.player_name))
	else
		local fs = self:render(player_name)
		minetest.show_formspec(self.player_name, self.name, fs)
		-- Redisplay the form 0.1 s after to ensure form is displayed (sometimes
		-- displaying a form right after closing one does not work).
		minetest.after(0.1, function(param) minetest.show_formspec(unpack(param)) end,
			{ self.player_name, self.name, fs})
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

	-- On close trigger
	if self.def.on_close and type(self.def.on_close)=='function' then
		self.def.on_close(self)
	end

	stack:pop()
	if stack:top() then
		-- Have to use 'after' to avoid the "double close escape" bug
		stack:top():refresh()
	else
		minetest.close_formspec(self.player_name, '')
	end
end

--------------------------------------------------------------------------------
-- API functions
--------------------------------------------------------------------------------

function nofs.show_form(player_name, def, context)
	local form = Form:new(player_name, def, context)
	form:show()
end

--------------------------------------------------------------------------------
-- Event management
--------------------------------------------------------------------------------

minetest.register_on_player_receive_fields(
	function(player, formname, fields)
		if not minetest.is_player(player) then
			return true -- Not a player (other receive fields wont be triggered)
		end
		local player_name = player:get_player_name()

		local form = nofs.get_form_stack(player_name):top()
		if form == nil then
			return false -- Not managed by NoFS
		end
		if form.name ~= formname then
			-- Wrong form, can happen if event from a previous form has not been recieved yet
			minetest.log('warning',
				string.format('[nofs] Received fields for form "%s" but expected fields for "%s". Ignoring.',
					formname, form.name))
			minetest.log('warning',
				string.format('[nofs] Suspicious formspec data recieved from player "%s".',
					player_name))

			-- Ignore event and redisplay top form
			form:refresh()
			return true
		end

		form:receive(fields)
	end
)
