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


--	Form stack mechanism
--	====================

local stacks = {}

local function get_stack(player_name)
	if stacks[player_name] == nil then
		stacks[player_name] = {}
	end
	return stacks[player_name]
end

function nofs.clear_stack(player_name)
	stacks[player_name] = nil
end

-- Get top form
function nofs.get_stack_top(player_name)
	local stack = get_stack(player_name)
	return stack[#stack]
end

-- Remove top form from stack
function nofs.stack_remove(player_name)
	local stack = get_stack(player_name)
	if #stack then
		table.remove(stack, #stack)
	end
end

-- Add a form on top of the stack (and add some extra fields on form)
function nofs.stack_add(player_name, form)
	if form and type(form)=="table" then

		local stack = get_stack(player_name)

		stack[#stack + 1] = form

		-- Form complementation
		if not form.context then
			form.context = {}
		end

		-- Name form if it is not named
		if not form.id then
			form.id = nofs.name..":form"..#stack
		end
	end
end

minetest.register_on_leaveplayer(nofs.clear_stack)
