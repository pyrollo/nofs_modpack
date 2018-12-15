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

local function get_player_stack(player)
	if type(player) ~= "string" then
		player = player:get_player_name()
	end

	if stacks[player] == nil then
		stacks[player] = {}
	end

	return stacks[player]
end


-- Get top form
function nofs.stack_get_top(player)
	local stack = get_player_stack(player)
	return stack[#stack]
end

-- Find a form by its id
function nofs.stack_get_by_id(player, form_id)
	for _, form in pairs(get_player_stack(player)) do
		if form.id == form_id then
			return form
		end
	end
	return nil
end

-- Remove top form from stack
function nofs.stack_remove(player)
	local stack = get_player_stack(player)
	if #stack then
		table.remove(stack, #stack)
	end
end

-- Add a form on top of the stack (and add some extra fields on form)
function nofs.stack_add(player, form)
	if form and type(form)=="table" then

		local stack = get_player_stack(player)

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
