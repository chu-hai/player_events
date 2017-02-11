------------------------------------------------------------------------------
--	Example for global callbacks
------------------------------------------------------------------------------

local hud_datas = {}

local function hud_add_new_line(player, name, data, color)
	if not player or not name or name == "" then
		return
	end

	local datas = hud_datas[player:get_player_name()]
	if datas.huds[name] then
		return
	end

	local id = player:hud_add({
		hud_elem_type = "text",
		position = {x = 0.7, y = 0},
		text = data or "",
		alignment = {x = 1, y = 0},
		offset = {x = 0, y = datas.lines * 20 + 10},
		number = color or 0xffffff
	})

	datas.lines = datas.lines + 1
	datas.huds[name] = {id = id}
end

local function hud_update(player, name, data, color)
	if not player or not name or name == "" then
		return
	end

	local datas = hud_datas[player:get_player_name()]
	if not datas.huds[name] then
		return
	end

	local id = datas.huds[name].id
	player:hud_change(id, "text", data)
	if color then
		player:hud_change(id, "number", color)
	end
end

local function get_item_desc(itemname)
	local def = minetest.registered_items[itemname]
	local desc = "N/A"
	if def then
		desc = def.description
	end

	return desc
end

minetest.register_on_joinplayer(function(player)
	hud_datas[player:get_player_name()] = {
		lines = 0,
 		huds = {}
	}

	hud_add_new_line(player, "separator_1", "Wield Item  -----------------------", 0x60e0ff)
	hud_add_new_line(player, "curr_wield", "Curr:")
	hud_add_new_line(player, "prev_wield", "Prev:")
	hud_add_new_line(player, "separator_2", "Position  -------------------------", 0x60e0ff)
	hud_add_new_line(player, "curr_pos", "Curr:")
	hud_add_new_line(player, "prev_pos", "Prev:")
	hud_add_new_line(player, "under_node", "Node:")
end)


player_events.register_on_change_wield(function(player, curr_wield_itemname, curr_wield_index, prev_wield_itemname, prev_wield_index)
	hud_update(player, "curr_wield", ("Curr: %d[%s]"):format(curr_wield_index, get_item_desc(curr_wield_itemname)))
	hud_update(player, "prev_wield", ("Prev: %d[%s]"):format(prev_wield_index, get_item_desc(prev_wield_itemname)))
end)

player_events.register_on_player_move(function(player, curr_pos, prev_pos)
	hud_update(player, "curr_pos", ("Curr: %s"):format(minetest.pos_to_string(curr_pos)))
	hud_update(player, "prev_pos", ("Prev: %s"):format(minetest.pos_to_string(prev_pos)))

	local desc = get_item_desc(minetest.get_node(vector.subtract(curr_pos, {x = 0, y = 1, z = 0})).name)
	hud_update(player, "under_node", ("Node: %s"):format(desc))
end)
