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

local fields_whitelist = { quit = true, key_enter = true, key_enter_field = true}

-- Event management
-- ================

-- Generic on receive fields
minetest.register_on_player_receive_fields(
	function(player, formname, fields)
		if not minetest.is_player(player) then
			return true -- Not a player (other receive fields wont be triggered)
		end
		local player_name = player:get_player_name()

		local form = nofs.get_stack_top(player_name)
		if form == nil then
			return false -- Not managed by NoFS
		end
		if form.id ~= formname then
			-- Wrong form, remove stack, close all (should not happen)
			minetest.log('warning',
				string.format('[nofs] Received fields for form "%s" but expected fields for "%s". Ignoring.',
					formname, form.id))
				minetest.log('warning',
					string.format('[nofs] Suspicious formspec data recieved from player "%s".', player_name))
			nofs.clear_stack(player_name)
			minetest.close_formspec(player)
			return false
		end

		-- Check fields
		local suspicious = false
		for key, value in pairs(fields) do
			local item = form.ids[key]
			if not fields_whitelist[key] and not item then
				minetest.log('warning',
					string.format('[nofs] Unwanted field "%s" for form "%s".',
						key, formname))
				suspicious = true
			end
		end
		if suspicious then
			minetest.log('warning',
				string.format('[nofs] Suspicious formspec data recieved from player "%s".', player_name))
		end

		-- Field events
		for id, item in pairs(form.ids) do
			if fields[id] then
				item:handle_field_event(fields[id])
			end
		end

		-- Form events
		-- close event
		-- If form exit, unstack
		if fields.quit == "true" then
			-- Trigger on_close event
--			nofs.trigger_event(player, form, fields, form, 'close')
			nofs.stack_remove(player_name)
		end

		nofs.refresh_form(player_name)
		--> End with a refresh / close to take in account modifications
	end
)
