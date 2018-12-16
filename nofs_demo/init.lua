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

local main_form = nofs.new_form({
	id = 'test_form',
	type = 'grid',
	{
		type = 'gridrow',
		{ type = 'label', width = 2, height = 1, label = 'Label 1',	},
		{	id = 'field 1',	type = 'field',	height = 1,	width = 4 },
	 	{	type = 'button', width = 2, height = 1, label = 'Test',
			on_clicked = function() print ('Button test clicked') end,
	 	},
	},
	{
		type = 'gridrow',
		{ type = 'label', width = 2, height = 1, label = 'Label 2',	},
		{	id = 'field 2',	type = 'field',	height = 1,	width = 6 },
		{	type = 'button', width = 1, height = 1, label = 'Test 2',
			on_clicked = function() print ('Button testé clicked') end,
		},
	},
	{
		type = 'gridrow',
		{ type = 'label', width = 2, height = 1, label = 'Label 3',	},
		{	id = 'field 3',	type = 'field',	height = 2,	width = 1 },
		{	type = 'button', width = 2, height = 2, label = 'Test 3',
			on_clicked = function() print ('Button clicked') end,
		},
	},
})


minetest.register_chatcommand("nofs", { params = "", description = "NOFS demo",
    func = function(name, param)
	      nofs.show_form(name, main_form)
	    end,
    }
)
