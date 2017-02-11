------------------------------------------------------------------------------
--	Example for on_playerevents_wield / on_playerevents_unwield event.
------------------------------------------------------------------------------
local function adjust_physics_override(player, speed, gravity, jump)
	local tbl = player:get_physics_override()
	tbl.speed   = tbl.speed   + (speed   or 0)
	tbl.gravity = tbl.gravity + (gravity or 0)
	tbl.jump    = tbl.jump    + (jump    or 0)

	player:set_physics_override(tbl)
end

minetest.register_tool("balloon:balloon", {
	description = ("Balloon"),
	inventory_image = "balloon_balloon.png",
	wield_image = "balloon_balloon.png",
	on_playerevents_wield = function(player)
		adjust_physics_override(player, 0, -0.9)
	end,

	on_playerevents_unwield = function(player)
		adjust_physics_override(player, 0, 0.9)
	end,
})

minetest.register_craft({
	output = "balloon:balloon 1",
	recipe = {
		{"default:paper", "default:paper", "default:paper"},
		{"default:paper", "default:paper", "default:paper"},
		{"",              "wool:white",    ""},
	}
})
