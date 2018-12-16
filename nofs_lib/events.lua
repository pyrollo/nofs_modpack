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

local function calliffunc(fct, ...)
	if type(fct) == 'function' then
		return fct(...)
	end
end

local fields_whitelist = { "quit", "key_enter", "key_enter_field" }

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
		if not minetest.is_player(player) then
			return true
		end

		local player_name = player:get_player_name()

		local form = nofs.get_stack_top(player_name)
		if form == nil then
			return false -- Not managed by NoFS
		end

		if form.id ~= formname then
			minetest.log('warning',
				string.format('[nofs] Received fields for form "%s" but expected fields for "%s". Ignoring.',
					formname, form.id))
			nofs.clear_stack(player_name)
			return false
		end

		-- Check fields
		local suspicious = false
		for key, value in pairs(fields) do
			local element = form.ids[key]
			if not fields_whitelist[key] and not element then
				minetest.log('warning',
					string.format('[nofs] Unwanted field "%s" for form "%s".', key, formname))
				suspicious = true
			end
			if element then
				local widget = nofs.get_widget(element.type)
				if widget.holds_value then
					if element.value ~= value then
						calliffunc(element.on_changed)
						element.value = value
					end
				end
			end
		end
		if suspicious then
			minetest.log('warning',
				string.format('[nofs] Suspicious fields recieved from player "%s".', player_name))
		end

		-- Clicked events
		for id, element in pairs(form.ids) do
			if fields[id] then
				calliffunc(element.on_clicked)
			end
		end

		-- close event
		-- If form exit, unstack
		if fields.quit == "true" then
			-- Trigger on_close event
			nofs.trigger_event(player, form, fields, form, 'close')
			nofs.stack_remove(player_name)
			local form = nofs.get_stack_top(player_name)
			if form then
				nofs.refresh_form(form, player)
			end
		end
	end
)
