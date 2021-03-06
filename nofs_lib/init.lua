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

nofs = {}
nofs.name = minetest.get_current_modname()
nofs.path = minetest.get_modpath(nofs.name)

dofile(nofs.path..'/stack.lua')
dofile(nofs.path..'/formspec.lua')
dofile(nofs.path..'/widgets_registry.lua')
dofile(nofs.path..'/widgets_containers.lua')
dofile(nofs.path..'/widgets_basic.lua')
dofile(nofs.path..'/widgets_composite.lua')
dofile(nofs.path..'/form.lua')
dofile(nofs.path..'/item.lua')
dofile(nofs.path..'/events.lua')

--dofile(nofs.path..'/render.lua')
