-- Maximum nodes that can be travelled with one usage.
local max_moves = tonumber(minetest.setting_get("sneakladder.max_moves")) or 1
-- Minimum moves before action is taken.
local min_moves = tonumber(minetest.setting_get("sneakladder.min_moves")) or 0
-- Maximum distance from the target, in single coordinates.
local max_dist = tonumber(minetest.setting_get("sneakladder.max_dist")) or 3
local max_y_dist = tonumber(minetest.setting_get("sneakladder.max_y_dist")) or 2.5
-- Allow "sneakladdering" down.
local down = minetest.setting_getbool("sneakladder.down") or true

minetest.register_entity("sneakladder:entity", {
    physical = false,
    timer = 0.1,
    collisionbox = {0,0,0,0,0,0},
    textures = {"default_cloud.png^[opacity:0"},
    visual_size = {x=0, y=0},

    on_step = function(self, dtime)
        self.timer = self.timer - dtime
        if self.timer <= 0 then
            self.object:remove()
            return
        end
    end,
})

minetest.register_tool("sneakladder:tool", {
    description = "Sneakladder Tool",
    inventory_image = "sneakladder_item.png",
    on_place = function(itemstack, user, pointed_thing)
        local pos = minetest.get_pointed_thing_position(pointed_thing)
        if not user or not pos then
            return
        end
        local pitch = user:get_look_vertical()
        local change = (pitch < 0) and 1 or -1

        if (not down) and (change == -1) then
            return
        end

        local target = vector.new(pos)
        local last = vector.new(user:get_pos())
        local diff = vector.apply(vector.round(vector.subtract(last, target)), function(n)
            if n == 0 then
                return 0
            elseif n < 0 then
                return -1
            else
                return 1
            end
        end)
        local used_moves = 0

        local function can_sneak_over(pos)
            local node = minetest.get_node_or_nil(pos)
            if not node then return false end
            return not minetest.registered_nodes[node.name].walkable
        end

        local function can_stand_on(pos)
            local node = minetest.get_node_or_nil(pos)
            if not node then return false end
            return minetest.registered_nodes[node.name].walkable
        end

        if math.abs(target.x - last.x) > max_dist or math.abs(target.y - last.y) > max_y_dist or math.abs(target.z - last.z) > max_dist then
            return
        end

        local canlast = false

        while used_moves < max_moves do
            if not can_stand_on(target) then break end
            target.y = target.y + change
            if not can_sneak_over(target) then break end
            last = vector.add(target, vector.divide(diff, {x=1.2, y=2, z=1.2}))
            if not can_sneak_over(last) or not can_sneak_over(vector.add(last, {x=0, y=change, z=0})) then break end
            canlast = true
            target.y = target.y + change
            used_moves = used_moves + 1
        end
        if canlast and used_moves >= min_moves then
            local obj = minetest.add_entity(pos, "sneakladder:entity")
            obj:set_pos(last)
            user:set_attach(obj, "", {x=0, y=0, z=0}, {x=0, y=0, z=0})
        end
    end,
})

minetest.register_craft({
    output = "sneakladder:tool",
    recipe = {
        {"", "group:wood", ""},
        {"group:stick", "group:leaves", "group:stick"},
        {"group:leaves", "group:stick", "group:leaves"}
    },
})
