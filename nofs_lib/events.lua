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

-- Event management
-- ================

-- Generic on receive fields
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
			-- Wrong form, remove stack, close all (should not happen)
			minetest.log('warning',
				string.format('[nofs] Received fields for form "%s" but expected fields for "%s". Ignoring.',
					formname, form.name))
				minetest.log('warning',
					string.format('[nofs] Suspicious formspec data recieved from player "%s".', player_name))
			nofs.get_form_stack(player_name):empty()
			return false
		end

		form:receive(fields)
	end
)
