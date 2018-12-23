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

-- Check that element.ids are unique and that elements have proper types
-- As instance and def tables have id and type fields, it works on both
local function check_element(element, ids)
	local ids = ids or {}

	assert(element.type, 'Element must have a type.')
	local widget = nofs.get_widget(element.type)
	assert(widget, 'Element type "'..element.type..'" unknown.')

	if element.id then
		assert(ids[element.id] == nil,
			'Id "'..element.id..'" already used in the same form.')
		ids[element.id] = element
	end

	for _, child in ipairs(element) do
		check_element(child, ids)
	end
end

--------------------------------------------------------------------------------
-- Form class

-- TODO: Checks :
-- element.def.max_items integer > 1
-- element.def.id should not start with '.' (reserved)

local Form = {}
--nofs.Form = Form

function Form:get_unused_id(prefix)
	local i = 1
	while self.ids[(prefix or "other")..i] do
		i = i + 1
	end
	return (prefix or "other")..i
end

function Form:register_id(element)
	if element.id then
		assert(self.ids[element.id] == nil,
			'Id "'..element.id..'" already used in the same form.')
		self.ids[element.id] = element
	end
end

function Form:register_or_create_id(element)
	if not element.id then
		element.id = self:get_unused_id(element.type)
	end
	self:register_id(element)
end

function Form:create_id_if_missing(element)
	if not element.id then
		element.id = self:get_unused_id(element.type)
		self:register_id(element)
	end
end

function Form:build_instance()
	local function build_instance(def, data)
		local data = data
		if type(data) ~= 'table' then
			minetest.log("warning", "[nofs] data passed to create_instance is not a table")
			data = {}
		end
		local instance = { def = def, type = def.type, data = data,
			widget = nofs.get_widget(def.type),
pos ={ x=0, y=0 } -- A virer?
		 }
		for _, childdef in ipairs(def) do
			if childdef.data then
				if data[childdef.data] and type(data[childdef.data]) == "table" then
					-- Data has children, multiple instances
					if #data[childdef.data] then
						for _, childdata in ipairs(data[childdef.data]) do
							instance[#instance+1] = build_instance(childdef, childdata)
						end
					else
						-- cas d'un enfant avec un data={} ne contenant que des champs
						-- A vérifier l'utilité
						instance[#instance+1] = build_instance(childdef, data[childdef.data])
					end
				else
					-- Cas habituel d'un enfant adressant directement un champ des data
					instance[#instance+1] = build_instance(childdef, data)
				end
			else
				-- Cas d'un enfant sans data
				instance[#instance+1] = build_instance(childdef, data)
			end
		end
		return instance
	end

	-- Instance creation
	self.instance = build_instance(self.def, self.data)
--	self.instance.pos = { x=0, y=0 }
end

function Form:new(def)
	assert(type(def) == "table", "Form definition must be a table.")

	def.type = "form"
	check_element(def)

	local form = {
		def = table.copy(def),
		instance = {},
		ids = {},
		data = {},
	}

	setmetatable(form, self)
	self.__index = self
	return form
end

function Form:render_element(element, offset)
	self:register_id(element)
	if element.widget.render then
		return element.widget.render(self, element, offset)
	else
		return ''
	end
end

function Form:render()
	local function size_element(element)
		-- first, size children (if any)
		for _, child in ipairs(element) do
			size_element(child)
		end

		if element.widget.size and type(element.widget.size) == 'function' then
			-- Specific sizing method
			element.widget.size(element)
		elseif element.widget.size and type(element.widget.size) == 'table' then
			-- Default size
			element.element.size = {
				x = element.def.width or element.widget.size.x,
				y = element.def.height or element.widget.size.y,
			}
		else
			element.size = { x = element.def.width, y = element.def.height }
		end
	end

	self:build_instance()

--[[
En fait, il faudrait copier les champs de def vers element si ceux-ci ne sont
pas des fonctions car ils sont potentiellement modifiables. Les fonctions ne
devraient pas être modifiables. On peut peut être les copier puisque ce ne sont
de toutes façons que des pointeurs.
]]
	size_element(self.instance)

	return self:render_element(self.instance, { x = 0, y = 0 })
--	return string.format("size[%g,%g]%s", self.instance.size.x, self.instance.size.y,
--		self:render_element(self.instance, {x = 0, y = 0}))
end

function nofs.is_form(form)
	local meta = getmetatable(form)
	return meta and meta == Form
end

function nofs.new_form(def)
	return Form:new(def)
end
