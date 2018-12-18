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

local widgets = {}

function nofs.register_widget(type_name, def)
	assert(widgets[type_name] == nil,
		string.format('Widget type "%s" already registered.', type_name))
	widgets[type_name] = table.copy(def)
end

-- Arg can be a type name or an element table
function nofs.get_widget(arg)
	if type(arg) == "string" then
		return widgets[arg]
	elseif type(arg) == "table" and arg.type then
		return widgets[arg.type]
	end
end
