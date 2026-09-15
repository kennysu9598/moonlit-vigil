extends Node2D

func _ready() -> void:
	var game = load("res://main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game._start_battle()
	game.phase = "gallery"
	game.busy = true
	game.music.stop()
	var folder := ProjectSettings.globalize_path("user://art-motion-" + Time.get_datetime_string_from_system().replace(":", "-"))
	DirAccess.make_dir_recursive_absolute(folder)
	for id in [0, 2]:
		var kind := "fire" if id == 0 else "dragon"
		for fixed in [true, false]:
			var label := ("phoenix" if id == 0 else "dragon") + ("-fixed" if fixed else "-flight")
			var sequence := folder + "/" + label
			DirAccess.make_dir_recursive_absolute(sequence)
			var targets: Array[Vector2] = [game.actors[3].home,game.actors[4].home,game.actors[5].home]
			var origin: Vector2 = Vector2(580,420) if fixed else game.actors[id].home
			game.models.start(id,2,origin,targets,true)
			game.combat.current_id = id
			game.selected_skill = 2
			game._refresh_hud()
			game.banner.text = "动作检查 · " + ("冻结位移" if fixed else "完整施放")
			for frame in range(60):
				var seconds := 0.16 + frame / 24.0
				game.models.debug_seek(seconds,fixed)
				game._environment(kind,minf(smoothstep(0.0,0.7,seconds),1.0-smoothstep(1.6,2.6,seconds)))
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(sequence + "/%03d.png" % frame)
			print("MOTION_SEQUENCE ",sequence)
			game.models.reset()
	print("ART_GALLERY_COMPLETE ",folder)
	get_tree().quit()
