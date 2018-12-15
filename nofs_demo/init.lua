--[[
	nofs_demo for Minetest - Demonstration mod for nofs_lib
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

nofs_demo = {}
nofs_demo.name = minetest.get_current_modname()
nofs_demo.path = minetest.get_modpath(nofs_demo.name)

--dofile(nofs.path..'/stack.lua')

local itemlist={}

minetest.after(0, function()
	for name, item in pairs(minetest.registered_items) do
		if item.description and item.description ~= "" and name ~= "air" then
			table.insert(itemlist, name)
		end
	end
	table.sort(itemlist)
end
)
--[[
new_form('test_form:itemlist', function(context)
	if not context.page then context.page = 1 end

	local formspec
	local grid = { x = 8, y = 7 }
	local pagesize = grid.x * grid.y
	local lastpage = math.ceil(#itemlist / pagesize)

	if context.page < 1 then context.page = 1 end
	if context.page > lastpage then context.page = lastpage end

	local count = pagesize * (context.page - 1)

	formspec = "size[8,9]label[0,0;Page "..context.page.." of "..lastpage.."]"

	local x, y
	for y = 1, grid.y do
		for x = 1, grid.x do
			count = count + 1
			if count < #itemlist then
	  			formspec = formspec.."item_image_button["..(x-1)..","..y..";1,1;"..itemlist[count]..";test_form:bi_"..itemlist[count]..";]"
			end
		end
	end

	formspec = formspec.."button[6,0;1,1;b_prev;<]button[7,0;1,1;b_next;>]button_exit[7,8;1,1;button_exit;Exit]"

	return formspec
end)

set_form_callback('test_form:itemlist', 'b_prev', function(formname, player, fields, context)
	context.page = context.page - 1
	refresh_form(formname, player)
end)

set_form_callback('test_form:itemlist', 'b_next', function(formname, player, fields, context)
	context.page = context.page + 1
--	refresh_form(formname, player)
	refresh_form('test_form:test', player)
end)

new_form('test_form:test', function(context)
return	render_form(test_form)
--return "size[3,3]button[0,0;3,1;item;Item chooser]button[0,1;3,1;test;Test]button_exit[0,2;3,1;button_exit;Exit]"
end)

set_form_callback('test_form:test', 'item', function(formname, player, fields, context)
	stack_form	("test_form:itemlist", player:get_player_name())
end)

set_form_callback('test_form:test', 'test', function(formname, player, fields, context)
	minetest.show_formspec(player_name(player), "", "")
end)
--]]

-- TODO :: PROBLEME : Les tableaux associatifs ne sont pas parcourrus dans l'ordre

local main_form = nofs.new_form({
	id = 'test_form',
	type = 'vbox',
	 { type = 'hbox',
 		{	type = 'label', width = 2, height = 1, label = 'A simple text',	},
	 	{	type = 'button', width = 2, height = 1, label = 'Test',
			on_action = function() print ('Button test clicked') end,
	 	},
	 	{	type = 'button', width = 2, height = 1,	label = 'Test 2',
			on_action = function() print ('Button test 2 clicked') end,
		},
	},
	{ type = 'hbox',
		{	id = 'field 1',	type = 'field',	height = 1,	width = 4,
			label = 'Field', default = 'toto',},
		{	type = 'button', height = 1,	width = 1, label = 'Exit', exit = 'true',
			on_action = nofs.close_form, },
	},
	{ type = "checkbox", width = 3, height =1, id = "chk1", label = "Select this", },
	{ type = "inventory", width = 7, height = 5, inventory = "current_player", list="main", listring=true },
})


minetest.register_chatcommand("nofs", { params = "", description = "NOFS demo",
    func = function(name, param)
	      nofs.show_form(name, main_form)
	    end,
    }
)
