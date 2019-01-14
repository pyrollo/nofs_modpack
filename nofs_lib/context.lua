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


-- Context:
-- Inherits
-- Protected (read only)
-- Local (element only)

-- set() --> local
-- set_inherit() --> inherits
-- set_protected() --> inherits protected
-- get()

local Context = {}

function nofs.is_context(context)
	local meta = getmetatable(context)
	return meta and meta == Context
end

local private = {} -- This is a private index for private data (could be any value except nil)

function Context:new(parent)
--	assert(nofs.is_item(item), 'First argument expected to be an Item')
	if parent then
		print(dump(parent))
		assert(nofs.is_context(parent), 'Parent, if any, expected to be a Context')
	end

	local new = {}
	new[private] = { values = {}, heritable = {}, parent = parent }
	setmetatable(new, Context)
	return new
end

function Context:__index(key)
	-- TODO: What is the best order ?
	if Context[key] ~= nil then
		return Context[key]
	end
	if self[private].values[key] ~= nil then
		return self[private].values[key]
	end
	-- TODO:not sure ?
--	if self[private].item.def[key] ~= nil then
--		return self[private].item.def[key]
--	end
	return self:get_heritage(key)
end

function Context:set_heritable(key)
	if self[private].values[key] then
		self[private].heritable[key] = true
	end
end

function Context:get_heritage(key)
	if self[private].values[key] and self[private].heritable[key] then
		return self[private].values[key]
	elseif self[private].parent then
		return self[private].parent:get_heritage(key)
	end
end

function Context:__newindex (key, value)
	self[private].values[key] = value
	if value == nil and self[private].heritable[key] then
		self[private].heritable[key] = nil
	end
end

-- Parent is the parent context in case of inheritance. Can be left nil
function nofs.new_context(parent)
	return Context:new(parent)
end
