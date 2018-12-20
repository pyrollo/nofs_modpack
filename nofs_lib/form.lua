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
--- Form class

local Form = {}
--nofs.Form = Form

function Form:new(def)
	-- Here, element is a part of def, not instance
	local function collect_ids(element, ids)
		if element.id then
			assert(ids[element.id] == nil,
				'Id "'..element.id..'" already used in the same form.')
			ids[element.id] = element
		end

		for _, child in ipairs(element) do
			collect_ids(child, ids)
		end
	end

	-- Here, element is a part of def, not instance
	local function add_missing_ids_and_check_types(element, ids)
		assert(element.type, 'Element must have a type.')
		local widget = nofs.get_widget(element.type)
		assert(widget, 'Element type "'..element.type..'" unknown.')

		if not element.id and (widget.needs_id or widget.holds_value) then
			local i = 1
			while ids[element.type..i] do
				i = i + 1
			end
			element.id = element.type..i
			ids[element.id] = element
		end

		for index, child in ipairs(element) do
			add_missing_ids_and_check_types(child, ids)
		end
	end

	if type(def) ~= "table" then
		minetest.log("error",
			"[nofs] Form definition must be a table.")
		return nil
	end

	local form = {
		def = table.copy(def),
		instance = {},
		ids = {},
		data = {},
	}

	form.def.type = form.def.type or "vbox"
	form.instance.pos = { x=0, y=0 }

	collect_ids(form.def, form.ids)
	add_missing_ids_and_check_types(form.def, form.ids)

	setmetatable(form, self)
	self.__index = self
	return form
end

function Form:render()
	-- Here, element is a part of instance, not def
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

--[[
En fait, il faudrait copier les champs de def vers element si ceux-ci ne sont
pas des fonctions car ils sont potentiellement modifiables. Les fonctions ne
devraient pas être modifiables. On peut peut être les copier puisque ce ne sont
de toutes façons que des pointeurs.
]]

	local function create_instance(def, data)
		local data = data
		if type(data) ~= 'table' then
			minetest.log("warning", "[nofs] data passed to create_instance is not a table")
			data = {}
		end
		local instance = { def = def, widget = nofs.get_widget(def.type),
			data = data, pos = { x=0, y=0 } }
		for _, childdef in ipairs(def) do
			if childdef.data then
				if data[childdef.data] and type(data[childdef.data]) == "table" then
					-- Data has children, multiple instances
					if #data[childdef.data] then
						for _, childdata in ipairs(data[childdef.data]) do
							instance[#instance+1] = create_instance(childdef, childdata)
						end
					else
						-- cas d'un enfant avec un data={} ne contenant que des champs
						-- A vérifier l'utilité
						instance[#instance+1] = create_instance(childdef, data[childdef.data])
					end
				else
					-- Cas habituel d'un enfant adressant directement un champ des data
					instance[#instance+1] = create_instance(childdef, data)
				end
			else
				-- Cas d'un enfant sans data=
				instance[#instance+1] = create_instance(childdef, data)
			end
		end
		return instance
	end

	-- Instance creation
	self.instance = create_instance(self.def, self.data)
	size_element(self.instance)

	return string.format("size[%g,%g]%s", self.instance.size.x, self.instance.size.y,
		self.instance.widget.render(self.instance, {x = 0, y = 0}))
end

function nofs.is_form(form)
	local meta = getmetatable(form)
	return meta and meta == Form
end

function nofs.new_form(def)
	return Form:new(def)
end
