------------------------------------------------------------------------------
--	Example for on_playerevents_step_in / on_playerevents_step_out event.
------------------------------------------------------------------------------

local crack_max_frame = 5
local cracked_ice_nodebase = "cracked_ice:cracked_ice_"

for i = 1, crack_max_frame do
	local node_name = cracked_ice_nodebase..i
	local prev_name = (i == 1) and "default:ice" or cracked_ice_nodebase..(i - 1)
	local def = table.copy(minetest.registered_nodes["default:ice"])

	def.description = "Cracked Ice "..i
	def.tiles = {("default_ice.png^(crack_anylength.png^[verticalframe:%i:%i^[colorize:#80c0ff:190)"):format(crack_max_frame, i - 1)}
	def.groups.not_in_creative_inventory = 1
	def.groups.cracked_ice = 1
	def.drop = "default:ice"
	def.previous_nodename = prev_name

	if i < crack_max_frame then
		def.on_playerevents_step_in = function(pos)
			local node = minetest.get_node(pos)
			node.name = cracked_ice_nodebase..(i + 1)
			minetest.swap_node(pos, node)
		end
	else
		def.on_playerevents_step_out = function(pos)
			minetest.dig_node(pos)
			minetest.sound_play("default_break_glass", {pos = pos, max_hear_distance = 10, gain = 1})
		end
	end

	minetest.register_node(node_name, def)
end

minetest.override_item("default:ice", {
	on_playerevents_step_in = function(pos)
		local node = minetest.get_node(pos)
		node.name = cracked_ice_nodebase.."1"
		minetest.swap_node(pos, node)
	end
})

minetest.register_abm({
	nodenames = {"group:cracked_ice"},
	interval = 3,
	chance = 3,
	action = function(pos, node, active_object_count, active_object_count_wider)
		node.name = minetest.registered_nodes[node.name].previous_nodename
		minetest.swap_node(pos, node)
	end
})
