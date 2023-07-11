--Docs
--[[
Configuration:
To add your own nodes that you want to compress further, you make a table like this:
<modname> = {
	{already_compressed = <how many times your final compression tier has been compressed, 0 if no compression>, node = <your final tier of compression's itemstring>},
	{already_compressed = <repeat>, node = <repeat>},
	.
	.
	<for every node you want compressed>
},
and append it to the to_compress table in the Config section.

You must also add the mod used to the mod.conf's optional_depends section.

LIMITATIONS:
Table-based textures (default:dirt_with_grass has them for example) are incompatible and cause the mod to return an error; Pull requests are welcome.
]]

--Config
to_compress = {
	default = {
		{already_compressed = 0, node = "stone"},
		{already_compressed = 0, node = "desert_stone"}
	},
}

if minetest.get_modpath("moreblocks") then
	to_compress["moreblocks"] = {
		{already_compressed = 1, node = "cobble_compressed"},
		{already_compressed = 1, node = "desert_cobble_compressed"},
		{already_compressed = 1, node = "dirt_compressed"},
	}
else
	to_compress["default"][3] = {already_compressed = 0, node = "cobble"}
	to_compress["default"][4] = {already_compressed = 0, node = "desert_cobble"}
	to_compress["default"][5] = {already_compressed = 0, node = "dirt"}
end

--Settings
maxlvl = tonumber(minetest.settings:get("max_compression_level") or 1)

--Main
darken_tiles = function(tiles, int--[[Can't find a good name]])
	if int>0 then
		for key, tile in pairs(tiles) do
			if type(tile) == "table" then
				error("\nTable found in texture.\nTexture found incompatible.")
			end
			for _=1, int, 1 do
				if _ <= tonumber(1 or 5) then
					tile = tile.."^compression_darken.png"
				end
			end
			tiles[key] = tile
		end
		return tiles
	end
end
register_compressed = function(node, name, level, mod, subordinate)
	node_groups = {compressed = level}
	for key, value in pairs(node.groups) do node_groups[key] = value end
	if node.already_compressed == 0 then node.displayname = "Compressed "..node.displayname end
	minetest.register_node(name, {
		description = node.displayname.." (Level "..level..") (x"..(9^level)..")",
		tiles = darken_tiles(node.tiles, level-node.already_compressed),
		groups = node_groups,
		sounds = node.sounds,
	})
	minetest.register_craft({
		type = "shapeless",
		recipe = {name},
		output = subordinate.." 9",
	})
	minetest.register_craft({
		type = "shapeless",
		recipe = {
			subordinate,
			subordinate,
			subordinate,
			subordinate,
			subordinate,
			subordinate,
			subordinate,
			subordinate,
			subordinate,
		},
		output = name,
	})
end

register_compression = function(mod, node_table)
	for _, node in ipairs(node_table) do
		node_name = mod..":"..node.node
		initial_node = minetest.registered_nodes[node_name]
		node.displayname = initial_node.description
		node.groups = initial_node.groups
		node.tiles = initial_node.tiles
		node.sounds = initial_node.sounds
		for level = node.already_compressed+1, maxlvl, 1 do
			if node.node ~= prior_node then name = nil end
			prior_node = node.node
			subordinate = name or node_name
			name = "compression:"..mod.."_"..node.node
			if node.already_compressed == 0 then
				name = name.."_level_"..level
			else
				name = name.."_compressed_level_"..level
			end
			register_compressed(node, name, level, mod, subordinate)
		end
	end	
end

for mod, node_table in pairs(to_compress) do
	if minetest.get_modpath(mod) then
		register_compression(mod, node_table)
	end
end
