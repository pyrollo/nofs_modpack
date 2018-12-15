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

-- Top level functions
-- ===================

-- Refreshes the top form
function nofs.refresh_form(player)
	local player = player
	local form = nofs.stack_get_top(player)
	if type(player) ~= "string" then
		player = player:get_player_name()
	end

	if form then
		minetest.show_formspec(player, form.id,
				form:render())
	else
		-- Hide form
		-- TODO:New function in API
		minetest.show_formspec(player, "", "")
	end
end

-- Show form
function nofs.show_form(player, form, params)
 	-- TODO : test form validity
	nofs.stack_add(player, form)

	if params then
		form.context['params'] = params
	end

--	nofs.trigger_event(player, form, { }, form, 'open')
	nofs.refresh_form(player)
end

-- Close top form
function nofs.close_form(player)
	local form = nofs.stack_get_top(player)
	if form then
		-- Like if "esc" key was pressed -- TODO: Check this
--		nofs.trigger_event(player, form, { quit = "true" }, form, 'close')
	end
	nofs.stack_remove(player)
	nofs.refresh_form(player)
end
