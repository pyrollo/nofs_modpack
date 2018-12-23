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


local main_form2 = nofs.new_form({
	id = 'test_form',
	type = 'vbox',
	 { type = 'hbox',
 		{	type = 'label', width = 2, height = 1, label = 'A simple text',	},
	 	{	type = 'button', width = 2, height = 1, label = 'Test',
			on_clicked = function() print ('Button test clicked') end,
	 	},
	 	{	type = 'button', width = 2, height = 1,	label = 'Test 2',
			on_clicked = function() print ('Button test 2 clicked') end,
		},
	},
	{ type = 'hbox',
		{	id = 'field 1',	type = 'field',	height = 1,	width = 4,
			label = 'Field', default = 'toto',},
		{	type = 'button', height = 1,	width = 1, label = 'Exit', exit = 'true',
			on_clicked = nofs.close_form, },
	},
	{ type = "checkbox", width = 3, height =1, id = "chk1", label = "Select this",
	on_clicked = function() print ('Checkbox pressed') end,},
	{ type = "inventory", width = 7, height = 5, inventory = "current_player", list="main", listring=true },
})

local data = {
	player = "toto",
	attribute = "xxx",
	meta = {
		{ name = "field1",	value = "xxx" },
		{ name = "field2",	value = "YYY" },
		{ name = "field3",	value = "zzz" },
		{ name = "field4",	value = "aaa" },
		{ name = "field5",	value = "bbb" },
	},
}

local main_form = nofs.new_form({
	id = 'test_form',
	type = 'vbox',
	max_items = 3,
	overflow = 'scrollbar',
	{
		type = 'hbox',
		{ type = 'label', width = 2, height = 1, value = "Player name",	},
		{	id = 'field 1',	type = 'field',	height = 1,	width = 4, data = "player" },
	},
	{
		type = 'hbox',
		data = "meta", -- Si meta contient des enfants, repete, sinon utilise ses champs
		{ type = 'label', width = 2, height = 1, data="name"},
		{ type = 'field', width = 2, height = 1, data="value"},
		{ type = 'button', width = 1, height = 1, label="...",
			on_clicked = function() print('clicked') end,},
	},
	{ type = 'hbox',
		{ type = 'button', width = 2, height = 1, label="Hello",
			on_clicked = function() print('Hello !') end,},
		{	type = 'button', height = 1,	width = 2, label = 'Exit', exit = 'true',
			on_clicked = nofs.close_form,
		},
	},
})

minetest.register_on_joinplayer(function(player)
	nofs.show_form(player:get_player_name(), main_form, data)
end)

minetest.register_chatcommand("nofs", { params = "", description = "NOFS demo",
	func = function(name, param)
		local fs = main_form:render(data)
		print()
		print(fs)
		print()
		nofs.show_form(name, main_form, data)
	end,
})
