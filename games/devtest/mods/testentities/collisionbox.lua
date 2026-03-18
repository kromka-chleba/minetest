-- Test entity for rotating collisionbox (rotate_collisionbox).
-- The entity has physical = true and collisionbox = {rotate = true},
-- so players collide with the rotated AABB of the oriented bounding box.

local function color(hex)
	return ("blank.png^[noalpha^[colorize:#%06X:255"):format(hex)
end

local function random_rotation()
	return 2 * math.pi * vector.new(math.random(), math.random(), math.random())
end

core.register_entity("testentities:collisionbox", {
	initial_properties = {
		visual = "cube",
		physical = true,
		collide_with_objects = false,
		infotext = "Rotating collisionbox test\n" ..
			"Players collide with the rotated hitbox\n" ..
			"Punch to randomize rotation, rightclick to toggle auto-rotation",
	},
	on_activate = function(self)
		-- Use a non-cubic shape so the rotation effect is obvious
		local w = math.random() * 0.5 + 0.25
		local h = math.random() * 0.5 + 0.25
		local l = math.random() * 0.5 + 0.25
		self.object:set_properties({
			textures = {
				color(0xFF4444), color(0x44FF44), color(0x4444FF),
				color(0xFFFF44), color(0xFF44FF), color(0x44FFFF),
			},
			visual_size = vector.new(w, h, l),
			collisionbox = {-w/2, -h/2, -l/2, w/2, h/2, l/2, rotate = true},
			selectionbox = {-w/2, -h/2, -l/2, w/2, h/2, l/2, rotate = true},
			automatic_rotate = 2 * math.pi * (math.random() - 0.5),
		})
		assert(self.object:get_properties().collisionbox.rotate,
			"collisionbox.rotate should be true after set_properties")
		self.object:set_armor_groups({punch_operable = 1})
		self.object:set_rotation(random_rotation())
	end,
	on_punch = function(self)
		self.object:set_rotation(random_rotation())
	end,
	on_rightclick = function(self)
		local props = self.object:get_properties()
		self.object:set_properties({
			automatic_rotate = props.automatic_rotate == 0
				and 2 * math.pi * (math.random() - 0.5) or 0,
		})
	end,
})
