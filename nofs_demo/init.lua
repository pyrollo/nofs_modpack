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
			on_clicked = function(item) item.form:close() end, },
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

local inspector_form = {
	id = 'test_form',
	spacing = 0.1,
	margin = 0.7,
	{ type = 'vbox',
		data = function(form)
			local pos = form:get_context().pos
			local node = minetest.get_node(pos)
			local ndef = minetest.registered_nodes[node.name]
			return { {
				title = string.format("Node: %s at %s\n", node.name, minetest.pos_to_string(pos)),
				param1 = string.format("Param1 (%s): %s\n", ndef.paramtype, node.param1),
				param2 = string.format("Param2 (%s): %s\n", ndef.paramtype2, node.param2),
			} }
		end,
		-- TODO: Creer un raccourci pour cette operation repetitive qui va être courrante
		{ type = 'label', height = 1, width = 6, init = function(item) item:get_context().label = item.parent:get_context().data.title end },
		{ type = 'label', height = 1, width = 6, init = function(item) item:get_context().label = item.parent:get_context().data.param1 end },
		{ type = 'label', height = 1, width = 6, init = function(item) item:get_context().label = item.parent:get_context().data.param2 end },
	},
	{ type = 'label', height = 1, width = 6, label = "Metadata:" },
	{ type = 'vbox',
		max_items = 3,
		overflow = 'scrollbar',
		{
			type = 'hbox',
			data = function(form)
					local data = {}
					local pos = form:get_context().pos
					if pos then
						local meta = minetest.get_meta(pos)
						local tab = meta:to_table()
						for key, value in pairs(tab.fields) do
							data[#data+1] = { key = key, value = value}
						end
					end
					return data
				end,
			{ type = 'label', width = 2, height = nofs.fs_field_height,
				init = function(item)
					item:get_context().label = item.parent:get_context().data.key
				end,
			},
			{ type = 'field', width = 4, height = nofs.fs_field_height,
				init = function(item)
					item:get_context().value = item.parent:get_context().data.value
				end,
				save = function(item)
					local meta = minetest.get_meta(item.form:get_context().pos)
					meta:set_string(item.parent:get_context().data.key, item:get_context().value)
				end,
			},
			{ type = 'button', width = 1, height = nofs.fs_field_height, label="...",
				on_clicked = function(item)
					local context = item.parent:get_context()
				end,
			},
		},
	},
	{ type = 'hbox',
		{ type = 'button', width = 2, height = 1, label="Cancel", exit = 'true', },
		{	type = 'button', height = 1,	width = 2, label = 'Save', exit = 'true',
			on_clicked = function(item) item.form:save() end
		},
	},
}


minetest.register_tool("nofs_demo:node_inspector", {
    description = "Node inspector dev tool",
    inventory_image = "nofs_demo_inspector.png",
    liquids_pointable = true,
    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type=="node" then
					nofs.show_form(user:get_player_name(), inspector_form,
						{ pos = pointed_thing.under })
	      elseif pointed_thing.type=="object" then
          print('Not implemented yet')
        end
      end
})
--[[

local function demo(player_name)
	local form = nofs.new_form(player_name, main_form)
	form:get_context().pos = { x = 0, y = 0, z = 0 }
end

minetest.register_on_joinplayer(function(player)
	local player_name = player:get_player_name()
	demo(player_name)
end)

minetest.register_chatcommand("nofs", { params = "", description = "NOFS demo",
	func = function(player_name, param)
		demo(player_name)
	end,
})
]]
