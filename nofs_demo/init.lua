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


local main_form2 = {
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
			label = 'Attribute "test"', meta="player:test",},
		{	type = 'button', height = 1,	width = 1, label = 'Exit', exit = 'true',
			on_clicked = nofs.close_form, },
	},
	{ type = "checkbox", width = 3, height =1, id = "chk1", label = "Select this",
	on_clicked = function() print ('Checkbox pressed') end,},
	{ type = "inventory", width = 7, height = 5, inventory = "current_player", list="main", listring=true },
}

local data = {
	player = "toto",
	attribute = "xxx",
	meta = {
		{ name = "field1",	value = "xxx" },
		{ name = "field2",	value = "YYY" },
		{ name = "field3",	value = "zzz" },
		{ name = "field4",	value = "aaa" },
		{ name = "field5",	value = "bbb" },
		{ name = "field6",	value = "xxx" },
		{ name = "field7",	value = "YYY" },
		{ name = "field8",	value = "zzz" },
		{ name = "field9",	value = "aaa" },
		{ name = "field10",	value = "bbb" },
		{ name = "field11",	value = "xxx" },
		{ name = "field12",	value = "YYY" },
		{ name = "field13",	value = "zzz" },
		{ name = "field14",	value = "aaa" },
		{ name = "field15",	value = "bbb" },
	},
}

local main_form = {
	id = 'test_form',
	{ type= 'hbox',
		{ type = 'vbox',
			{ type = 'label', width = 2, height = 1, value = 'Attribute "test"',	},
			{ id = 'field 1', type = 'field', height = 1,	width = 4, meta = "player:test" },
			{ type = 'hbox',
				{ type = 'button', width = 2, height = 1, label="Hello",
					on_clicked = function() print('Hello !') end,},
				{	type = 'button', height = 1,	width = 2, label = 'Exit', exit = 'true',
					on_clicked = function(item) item.form:save() end
				},
			},
		},
		{ type = 'vbox',
			max_items = 6,
			overflow = 'scrollbar',
			{
				type = 'hbox',
				data = "meta", -- Si meta contient des enfants, repete, sinon utilise ses champs
				{ type = 'label', width = 2, height = 1, data="name"},
				{ type = 'field', width = 2, height = 1, data="value"},
				{ type = 'button', width = 1, height = 1, label="...",
					on_clicked = function() print('clicked') end,
				},
			},
		},
	},
}

minetest.register_on_joinplayer(function(player)
	local player_name = player:get_player_name()
	nofs.show_form(player_name, nofs.new_form(player_name, main_form), data)
end)

minetest.register_chatcommand("nofs", { params = "", description = "NOFS demo",
	func = function(player_name, param)
		nofs.show_form(player_name, nofs.new_form(player_name, main_form), data)
	end,
})
