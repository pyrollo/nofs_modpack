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


--	Stack class
--	===========

local Stack = {}
Stack.__index = Stack

function Stack:new()
	stack = {}
	setmetatable(stack, self)
	return stack
end

function Stack:top()
	if #self > 0 then
		return self[#self]
	end
end

function Stack:push(item)
	self[#self + 1] = item
end

function Stack:pop()
	local item = self:top()
	if item then
		self[#self] = nil
		return item
	end
end

function Stack:clear()
	local count = #self
	for index=0, count do
		self[index] = nil
	end
end

function stack:remove(item)
	local count = #self
	local new = 1
	for index = 1, count do
		if self[index] ~= item then
			self[new] = self[index]
			new = new +1
		end
	end

	for index = new, count do
		self[index] = nil
	end
end


-- Player form stacks
-- ==================

local stacks = {}

minetest.register_on_leaveplayer(function(player)
		stacks[player:get_player_name()] = nil
	end)

function nofs.get_form_stack(player_name)
	if stacks[player_name] == nil then
		stacks[player_name] = Stack:new()
	end
	return stacks[player_name]
end
