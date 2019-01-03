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

local Context = {}

local private = {} -- This is a private index for private data (could be any value except nil)

function Context:__index(key)
	-- TODO: What is the best order ?
	if Context[key] ~= nil then
		return Context[key]
	end
	if self[private].data[key] ~= nil then
		return self[private].data[key]
	end
	if self[private].item.def[key] ~= nil then
		return self[private].data[key]
	end
	if parent ~= nil then
		return parent[key]
	end
end

function Context:__newindex (key, value)
	self[private].data[key] = value
end

function Context:new(item, parent)
	assert(nofs.is_item(item), 'First argument expected to be an Item')
	if parent then
		assert(nofs.is_context(parent), 'Parent, if any, expected to be a Context')
	end

	local new = {}
	new[private] = { data = {}, item = item, parent = parent }
	setmetatable(new, Context)
	return new
end

function Context:get_item()
	return self[private].item
end

function nofs.is_context(item)
	local meta = getmetatable(item)
	return meta and meta == Context
end

-- Parent is the parent context in case of inheritance. Can be left nil
function nofs.new_context(item, parent)
	return Context:new(item, parent)
end
