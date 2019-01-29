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

local inspector_form = {
	id = 'test_form',
	spacing = 0.1,
	margin = 0.7,
	{ type = 'tab', label = 'node', orientation = 'vertical',
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
		-- Ajouter un champ "context" pour lier le label au context ou un "${title}" comme valeur ?
		{ type = 'label', height = 1, width = 6, init = function(item) item:get_context().label = item:get_data('title') end },
		{ type = 'label', height = 1, width = 6, init = function(item) item:get_context().label = item:get_data('param1') end },
		{ type = 'label', height = 1, width = 6, init = function(item) item:get_context().label = item:get_data('param2') end },
	},
	{ type = 'tab', label = 'meta', layout = 'vertical',
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
				{ type = 'label', width = 2,
					init = function(item)
							item:get_context().label = item:get_data('key')
						end,
				},
				{ type = 'field', width = 4,
					init = function(item)
							item:get_context().value = item:get_data('value')
						end,
					save = function(item)
						local meta = minetest.get_meta(item.form:get_context().pos)
						meta:set_string(item:get_data('key'), item:get_context('value'))
					end,
				},
				{ type = 'button', width = 1, label="...",
					on_clicked = function(item)
						nofs.show_form(item.form.player_name,
							{ id = 'test_form',
								spacing = 0.5,
								margin = 0.7,
								{ type = 'label', width = 5,
									init = function(item) item:get_context().label = item:get_data('title') end },
								{ type = 'textarea', width = 5, height = 5,
									init = function(item) item:get_context().value = item:get_data('value') end,
									save = function(item) minetest.get_meta(item.form:get_context().pos, item.form:get_context().key, item.form:get_context().value) end,
								},
								{ type = 'hbox',
									{ type = 'button', exit = true, label = 'Back' },
									{ type = 'button', exit = true, label = 'Save', on_clicked = nofs.event.save },
								},
							},
							{ title = data.key, key = data.key, value = data.value, pos = item.form:get_context().pos })
					end,
				},
			},
		},
	},
	{ type = 'tab', label = 'inventory', orientation = 'vertical',
		max_items = 1, id = 'inventory',
		{ type = 'vbox',
				data = function(form)
					local data = {}
					local pos = form:get_context().pos
					if pos then
						local inv = minetest.get_meta(pos):get_inventory()
						for key, _ in pairs(inv:get_lists()) do
							data[#data+1] = { list = key }
						end
					end
					return data
				end,
			{ type = 'hbox',
				{ type = 'label', width = 4,
					init = function(item) item:get_context().label = 'Inventory: '..
						item:get_context().list end },
				{ type = 'pager', connected_to = 'inventory' },
			},
			{ type = 'inventory', height = 5, width = 8,
				init = function(item)
						local pos = item.form:get_context().pos
						local context = item:get_context()
						context.location = string.format('nodemeta:%g,%g,%g',
							pos.x, pos.y, pos.z)
					end
			}
		},
	},
	{ type = 'hbox',
		{ type = 'button', width = 2, label= 'Cancel', exit = true, },
		{	type = 'button', width = 2, label = 'Save', exit = true,
				on_clicked = nofs.event.save },
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
