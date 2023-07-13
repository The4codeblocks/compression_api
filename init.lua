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

local new_node = {info = {}}
compression = {}

--Settings
maxlvl = tonumber(core.settings:get("max_compression_level") or 10)

--Main
table.copy = function(tbl)
    local copy
    if type(tbl) == "table" then
        copy = {}
        for orig_key, orig_value in next, tbl, nil do
            copy[table.copy(orig_key)] = table.copy(orig_value)
        end
        setmetatable(copy, table.copy(getmetatable(tbl)))
    else
        copy = tbl
    end
    return copy
end

compression.darken_tiles = function(tiles, count)
	if count>0 then
		for key, tile in pairs(tiles) do
			if type(tile) == "table" then
				tile = darken_tiles(tile, count)
			else
				for _=1, count, 1 do
					if _ <= tonumber(1 or 5) then
						tile = tile.."^compression_darken.png"
					end
				end
			end
			tiles[key] = tile
		end
		return tiles
	end
end
register_compressed = function(node, new_node)
	core.register_node(new_node.info.name, table.copy(new_node.def))
	core.register_craft({
		type = "shapeless",
		recipe = {},
		output = new_node.info.subordinate.." 9",
	})
	core.register_craft({
		type = "shapeless",
		recipe = {
			new_node.info.subordinate,
			new_node.info.subordinate,
			new_node.info.subordinate,
			new_node.info.subordinate,
			new_node.info.subordinate,
			new_node.info.subordinate,
			new_node.info.subordinate,
			new_node.info.subordinate,
			new_node.info.subordinate,
		},
		output = new_node.info.name,
	})
end

compression.register_compressed_tiers = function(node)
	new_node.def = table.copy(core.registered_nodes[node])
	new_node.info.initial_compression = new_node.def.groups.compressed or 0
	new_node.info.original_description = new_node.def.description
	for level = new_node.info.initial_compression+1, maxlvl, 1 do
		if node ~= prior_node then new_node.info.name = nil end
		local prior_node = node
		if new_node.info.initial_compression == 0 then new_node.def.description = "Compressed "..new_node.def.description end
		new_node.info.subordinate = new_node.info.name or node
		new_node.info.name = "compression:"..(node:gsub(":","_"))
		if new_node.info.initial_compression == 0 then
			new_node.info.name = new_node.info.name.."_compressed_level_"..level
		else
			new_node.info.name = new_node.info.name.."_level_"..level
		end
		new_node.def.groups.compressed = level
		new_node.def.description = new_node.info.original_description.." (Level "..level..") (x"..(9^level)..")"
		new_node.def.tiles = compression.darken_tiles(new_node.def.tiles, level-new_node.info.initial_compression)
		new_node.def.drop = node
		register_compressed(node, new_node)
	end
end

compression.register_compressed_nodes = function(nodes)
	for _, node in ipairs(nodes) do
		compression.register_compressed_tiers(node)
	end
end
