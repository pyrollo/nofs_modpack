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
		root = table.copy(def),
		ids = {},
	}

	form.root.type = form.root.type or "vbox"
	form.root.pos = { x=0, y=0 }

	collect_ids(form.root, form.ids)
	add_missing_ids_and_check_types(form.root, form.ids)

	setmetatable(form, self)
	self.__index = self
	return form
end

function Form:render()
	local function size_element(element)
		-- first, size children (if any)
		for _, child in ipairs(element) do
			size_element(child)
		end

		local widget = nofs.get_widget(element.type)

		if widget.size and type(widget.size) == 'function' then
			-- Specific sizing method
			widget.size(element)
		elseif widget.size and type(widget.size) == 'table' then
			-- Default size
			element.size = {
				x = element.width or widget.size.x,
				y = element.height or widget.size.y,
			}
		else
			element.size = { x = element.width, y = element.height }
		end
	end


	size_element(self.root)

	return string.format("size[%g,%g]%s", self.root.size.x, self.root.size.y,
		nofs.get_widget(self.root.type).render(self.root, {x = 0, y = 0}))
end

function nofs.is_form(form)
	local meta = getmetatable(form)
	return meta and meta == Form
end

function nofs.new_form(def)
	return Form:new(def)
end
