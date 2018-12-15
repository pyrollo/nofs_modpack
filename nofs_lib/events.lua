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

-- TODO : Trigger on forms and containers ? = if one of the decendant matches
function nofs.trigger_event(player, form, fields, element, eventname)
	if element['on_'..eventname] and element.id and fields[element.id] then
		element['on_'..eventname](player, form, fields)
	end

 	if element.children then
		for index, child in ipairs(element.children) do
			nofs.trigger_event(player, form, fields, child, eventname)
		end
	end
end

-- Generic trigger propagation
minetest.register_on_player_receive_fields(
	function(player, formname, fields)
		-- Find form -- TODO: Manage case of unwanter form
		local form = nofs.stack_get_by_id(player, formname)
		if form then
			-- Trigger on_click event
			
			nofs.trigger_event(player, form, fields, form, 'action')

			-- If form exit, unstack
			if fields.quit == "true" then
				-- Trigger on_close event
				nofs.trigger_event(player, form, fields, form, 'close')
				nofs.stack_remove(player)
				local form = nofs.stack_get_top(player)
				if form then
					nofs.refresh_form(form, player)
				end
			end
		end
	end
)
