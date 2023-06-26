--Docs
--[[
Configuration:
To add your own nodes that you want to compress further, you make a table like this:
<modname> = {
	{already_compressed = <how many times your final compression tier has been compressed, 0 if no compression>, node = <your final tier of compression's itemstring>, displayname = <the node's original display name>},
	{already_compressed = <repeat>, node = <repeat>, displayname = <repeat>},
	.
	.
	<for every node you want compressed>
},
and append it to the to_compress table in the Config section.
]]

--Config
to_compress = {
	moreblocks = {
		{already_compressed = 1, node = "cobble_compressed", displayname = "Compressed Cobblestone"},
		{already_compressed = 1, node = "desert_cobble_compressed", displayname = "Compressed Desert Cobblestone"},
		{already_compressed = 1, node = "dirt_compressed", displayname = "Compressed Dirt"},
	},
}

--Settings
maxlvl = 5

--Main
register_compressed = function(node, name, level, already_compressed)
	texture = node..".png"
	if level > already_compressed then
		for _=0, level - already_compressed, 1 do
			texture
		end
	end
	minetest.register_node(name)
end

register_compresseds = function(mod, table)
	for _ node in ipairs(table) do
		for level = node.already_compressed+1, maxlvl, 1
			name = "compression:"..mod.."_"..node.node
			if node.already_compressed then
				name = name.."_level_"..level
			else
				name = name.."_compressed_level_"..level
			end
			register_compressed(node.node, name, level, node.already_compressed)
		end
	end	
end

for mod, table in pairs(to_compress) do
	if minetest.get_modpath(mod) then
		register_compression(mod, table)
	end
end
