player_events = {}

local player_lists = {}
local event_emitter = {}
local registered_event_player_move = {}
local registered_event_change_wield = {}

local jump_adjust_threshold = tonumber(minetest.settings:get("player_events.jump_adjust_threshold")) or 0.3

-------------------------------------------
----  Global Functions
-------------------------------------------
function player_events.register_on_player_move(callback_func)
	if type(callback_func) ~= "function" then
		minetest.log("error", "Invalid arguments for player_events.register_on_player_move().")
		return
	end

	table.insert(registered_event_player_move, callback_func)
end

function player_events.register_on_change_wield(callback_func)
	if type(callback_func) ~= "function" then
		minetest.log("error", "Invalid arguments for player_events.register_on_change_wield().")
		return
	end

	table.insert(registered_event_change_wield, callback_func)
end


-------------------------------------------
----  Utility Functions
-------------------------------------------
local function adjust_player_pos(pos)
	return {
		x = math.floor(pos.x + 0.5),
		y = math.ceil (pos.y - 0.5),
		z = math.floor(pos.z + 0.5),
	}
end

local function get_above_pos(pos)
	return {x = pos.x, y = pos.y + 1, z = pos.z}
end

local function get_under_pos(pos)
	return {x = pos.x, y = pos.y - 1, z = pos.z}
end


-------------------------------------------
----  Event Functions
-------------------------------------------
function event_emitter.player_move(player, tbl)
	local raw_pos = player:getpos()
	local pos = adjust_player_pos(raw_pos)
	local prev_pos = tbl.pos

	-- adjust Y position
	if minetest.get_node(pos).name == "air"
	and player:get_player_velocity().y > 0
	and math.abs(raw_pos.y - pos.y) < jump_adjust_threshold then
		pos.y = pos.y - 1
	end

	if not prev_pos or not vector.equals(prev_pos, pos) then
		local dir = prev_pos and vector.direction(prev_pos, pos).y or vector.new()
		if prev_pos then
			-- step_out event
			local prev_node = minetest.get_node(prev_pos)
			local def = minetest.registered_nodes[prev_node.name]
			if def and def.on_playerevents_step_out then
				def.on_playerevents_step_out(prev_pos, player, dir)
			end
		end

		-- step_in event
		tbl.pos = pos
		local new_node = minetest.get_node(pos)
		local def = minetest.registered_nodes[new_node.name]
		if def and def.on_playerevents_step_in then
			def.on_playerevents_step_in(pos, player, dir)
		end

		-- player_move event
		for _, callback in ipairs(registered_event_player_move) do
			callback(player, get_above_pos(pos), get_above_pos(prev_pos or pos))
		end
	end
end

function event_emitter.change_wield(player, tbl)
	local curr_wield_itemname = player:get_wielded_item():get_name()
	local prev_wield_itemname = tbl.wield_itemname or "n/a"
	local curr_wield_index = player:get_wield_index()
	local prev_wield_index = tbl.wield_index or -1


	if (prev_wield_index ~= curr_wield_index) or (prev_wield_itemname ~= curr_wield_itemname) then
		tbl.wield_itemname = curr_wield_itemname
		tbl.wield_index = curr_wield_index

		if prev_wield_index ~= -1 then
			-- unwield event
			local def = minetest.registered_items[prev_wield_itemname]
			if def and def.on_playerevents_unwield then
				def.on_playerevents_unwield(player)
			end
		end

		-- wield event
		local def = minetest.registered_items[curr_wield_itemname]
		if def and def.on_playerevents_wield then
			def.on_playerevents_wield(player)
		end

		-- change_wield event
		for _, callback in ipairs(registered_event_change_wield) do
			callback(player, curr_wield_itemname, curr_wield_index, prev_wield_itemname, prev_wield_index)
		end
	end
end


-------------------------------------------
----  Register callbacks
-------------------------------------------
minetest.register_on_joinplayer(function(player)
	local function check_and_add_player()
		local u_pos = get_under_pos(adjust_player_pos(player:getpos()))
		local node = minetest.get_node(u_pos)
 		if not node or node.name == "ignore" then
			minetest.after(0.1, check_and_add_player)
			return
		end
		player_lists[player:get_player_name()] = {}
	end

	check_and_add_player()
end)

minetest.register_on_leaveplayer(function(player)
	-- emit event: on_playerevents_step_out()
	local pos = player_lists[player:get_player_name()].pos
	local node = minetest.get_node(pos)
	local def = minetest.registered_nodes[node.name]
	if def and def.on_playerevents_step_out then
		def.on_playerevents_step_out(pos, player)
	end

	-- emit event: on_playerevents_unwield()
	local wield_itemname = player:get_wielded_item():get_name()
	if wield_itemname then
		local def = minetest.registered_items[wield_itemname]
		if def and def.on_playerevents_unwield then
			def.on_playerevents_unwield(player)
		end
	end

	player_lists[player:get_player_name()] = nil
end)


minetest.register_globalstep(function(dtime)
	for pname, tbl in pairs(player_lists) do
		local player = minetest.get_player_by_name(pname)

		-- step_in / step_out / player_move event
		event_emitter.player_move(player, tbl)

		-- wield / unwield / change_wield event
		event_emitter.change_wield(player, tbl)
	end
end)

minetest.log("action", "[Player Events] Loaded!")
