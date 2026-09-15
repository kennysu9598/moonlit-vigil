extends SceneTree
const FX = preload("res://scripts/art_fx.gd")
func _init() -> void: call_deferred("run")
func run() -> void:
	var fx = FX.new()
	root.add_child(fx)
	var targets: Array[Vector2] = [Vector2(950, 420)]
	fx.start(1, 2, Vector2(320, 400), targets, true)
	assert(not fx.active and fx.get_child_count() == 0)
	for unit in [0, 2]:
		fx.start(unit, 2, Vector2(320, 400), targets, true)
		assert(fx.active and fx.get_child_count() == 1)
		if unit == 0:
			assert(fx._frames.size() == 4)
			var aligned_eye: Vector2 = fx.EYES[0] / 627.0 * fx.PHOENIX_SIZE
			var times := [0.01, 0.29, 0.43, 0.15]
			for frame in range(4):
				fx.debug_seek(times[frame], true)
				assert(fx._frame == frame)
				assert(fx._polygon.texture.get_size() == Vector2(627, 627))
				assert(fx._polygon.texture == fx._frames[frame])
				for uv in fx._polygon.uv:
					assert(uv.x >= 0 and uv.x <= 627 and uv.y >= 0 and uv.y <= 627)
				var eye: Vector2 = fx.debug_anchor_pose(fx.EYES[frame] / 627.0, times[frame])
				assert(eye.distance_to(aligned_eye) < 0.001, "Eye should align exactly")
				print("ATLAS_FRAME frame=%d region=%s eye=%s fixed_size=400" % [frame, Rect2i((frame % 2) * 627, (frame / 2) * 627, 627, 627), eye])
			# Cadence uses elapsed delta rather than number of rendered frames.
			fx._time = 0.0
			for step in range(42): fx._process(1.0 / 60.0)
			var slow_frame: int = fx._frame
			fx._time = 0.0
			for step in range(14): fx._process(3.0 / 60.0)
			assert(fx._frame == slow_frame)
			fx.debug_seek(1.25, true)
			assert(fx._frame == 2, "Final dash tucks wings")
		var anchors: Array = [Vector2(0.65, 0.48), Vector2(0.15, 0.15), Vector2(0.30, 0.9), Vector2(0.92, 0.52)] if unit == 0 else [Vector2(0.86, 0.26), Vector2(0.72, 0.58), Vector2(0.17, 0.47), Vector2(0.45, 0.88)]
		for i in range(1, anchors.size()):
			var v0: Vector2 = fx.debug_anchor_pose(anchors[i], 0.18) - fx.debug_anchor_pose(anchors[0], 0.18)
			var v1: Vector2 = fx.debug_anchor_pose(anchors[i], 0.52) - fx.debug_anchor_pose(anchors[0], 0.52)
			print("ART_LOCAL unit=%d anchor=%d distance_a=%.3f distance_b=%.3f angle_delta_deg=%.3f relative_motion_px=%.3f" % [unit, i, v0.length(), v1.length(), rad_to_deg(v0.angle_to(v1)), v0.distance_to(v1)])
			if unit == 2: assert(v0.distance_to(v1) > 0.5)
		fx.debug_seek(0.18, true)
		var origin: Vector2 = fx._polygon.position
		var first: PackedVector2Array = fx._polygon.polygon
		fx.debug_seek(0.52, true)
		assert(origin == fx._polygon.position and first != fx._polygon.polygon, "Only local geometry must change")
		# Every triangle shares indexed vertices; test no foldover at sampled poses.
		var min_area: float = INF
		for sample in range(20):
			fx.debug_seek(sample * 0.1, true)
			var points: PackedVector2Array = fx._polygon.polygon
			for tri in fx._polygon.polygons:
				var area: float = (points[tri[1]] - points[tri[0]]).cross(points[tri[2]] - points[tri[0]])
				min_area = minf(min_area, area)
		assert(min_area > 0.0, "Mesh must not fold over")
		print("ART_TOPOLOGY unit=%d vertices=%d triangles=%d min_signed_area=%.3f" % [unit, fx._base.size(), fx._polygon.polygons.size(), min_area])

		for sample in range(20):
			fx.debug_seek(sample * 0.1, false)
			for index in fx._visible_indices:
				var screen: Vector2 = fx._polygon.polygon[index] + fx._polygon.position
				assert(screen.x >= 80.0 and screen.x <= 1200.0 and screen.y >= 145.0 and screen.y <= 575.0, "Visible anatomy outside battlefield")
		var rigid_center := Vector2(0.74, 0.75) if unit == 0 else Vector2(0.91, 0.48)
		var ra: Vector2 = fx.debug_anchor_pose(rigid_center, 0.18)
		var rb: Vector2 = fx.debug_anchor_pose(rigid_center + Vector2(0.025, 0), 0.18)
		var rc: Vector2 = fx.debug_anchor_pose(rigid_center, 0.52)
		var rd: Vector2 = fx.debug_anchor_pose(rigid_center + Vector2(0.025, 0), 0.52)
		assert(absf(ra.distance_to(rb) - rc.distance_to(rd)) < 0.01, "Claw scale must stay rigid")
		print("ART_BOUNDS_AND_RIGIDITY unit=%d claw_length_a=%.3f claw_length_b=%.3f PASS" % [unit, ra.distance_to(rb), rc.distance_to(rd)])
		fx.reset()
		assert(not fx.active and fx.get_child_count() == 0)
		fx.start(unit, 2, Vector2(320, 400), targets, true)
		fx._process(2.9)
		assert(not fx.active and fx.get_child_count() == 0)
	await process_frame
	fx.queue_free()
	print("ART_FX_TEST PASS local_motion/freeze/shared_mesh/no_fold/reset/expiry; aesthetics NOT evaluated")
	quit()
