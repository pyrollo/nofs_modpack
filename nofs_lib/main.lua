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
function nofs.refresh_form(player_name)
	local form = nofs.get_stack_top(player_name)

	if form then
		minetest.show_formspec(player_name, form.id,
				form:render())
	else
		-- Hide form
		minetest.close_formspec(player_name)
	end
end

-- Show form
function nofs.show_form(player_name, form, data)
 	-- TODO : test form validity
	nofs.stack_add(player_name, form)

	if data then
		form.context['data'] = data
	end

--	nofs.trigger_event(player, form, { }, form, 'open')
	nofs.refresh_form(player_name)
end

-- Close top form
function nofs.close_form(player_name)
	local form = nofs.get_stack_top(player_name)
	if form then
		-- Like if "esc" key was pressed -- TODO: Check this
--		nofs.trigger_event(player, form, { quit = "true" }, form, 'close')
	end
	nofs.stack_remove(player_name)
	nofs.refresh_form(player_name)
end
