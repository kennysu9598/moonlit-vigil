class_name MoonActor
extends Node2D

var unit: Dictionary = {}
var font: Font
var selected := false
var active := false
var home := Vector2.ZERO
var sprite: Sprite2D
var elapsed := 0.0
var acting := false
var sprite_height := 235.0
var atlas_texture: Texture2D
var row := 0
# Measured alpha bounds in the 1254px originals, with a small transparent gutter.
const HERO_REGIONS = [
 [Rect2(71, 0, 374, 400), Rect2(657, 18, 577, 382)],
 [Rect2(81, 403, 416, 416), Rect2(632, 401, 612, 417)],
 [Rect2(70, 811, 411, 426), Rect2(676, 868, 566, 351)]
]
const ENEMY_REGIONS = [
 [Rect2(49, 28, 506, 356), Rect2(622, 80, 611, 298)],
 [Rect2(129, 428, 436, 368), Rect2(683, 435, 527, 364)],
 [Rect2(65, 803, 522, 407), Rect2(744, 803, 460, 408)]
]
# Anatomical foot midpoint, in original atlas coordinates (not crop center).
const HERO_FEET = [[Vector2(305,398),Vector2(899,398)], [Vector2(270,817),Vector2(900,813)], [Vector2(319,1235),Vector2(895,1217)]]
const ENEMY_FEET = [[Vector2(284,382),Vector2(969,376)], [Vector2(347,794),Vector2(960,797)], [Vector2(343,1208),Vector2(936,1209)]]
var regions: Array = []
var feet: Array = []
var pose_base := Vector2.ZERO
var hurt_tween: Tween
var rotation_tween: Tween
var death_tween: Tween
var pose := 0
var health_layer: Node2D
var base_scale := Vector2.ONE
var hurt_pulse := 0.0
var idle_tween: Tween
var pulse_tween: Tween
var jitter_tween: Tween

func setup(data: Dictionary, p_font: Font, atlas: Texture2D, p_row: int) -> void:
	unit = data.duplicate(true)
	font = p_font
	atlas_texture = atlas
	row = p_row
	if int(unit.id) == 5:
		sprite_height = 280.0
	sprite = Sprite2D.new()
	sprite.show_behind_parent = true
	add_child(sprite)
	health_layer = Node2D.new()
	health_layer.z_as_relative = false
	health_layer.z_index = 88
	add_child(health_layer)
	health_layer.draw.connect(_draw_health)
	if atlas != null:
		regions = HERO_REGIONS[row] if int(unit.team) == 0 else ENEMY_REGIONS[row]
		feet = HERO_FEET[row] if int(unit.team) == 0 else ENEMY_FEET[row]
		# The healer's last four foot rows overlap the rogue's first hair rows.
		# Clean only that neighbouring fragment in a private in-memory copy.
		if int(unit.team) == 0 and row > 0:
			var pixels: Image = atlas.get_image()
			if pixels.is_compressed():
				pixels.decompress()
			pixels.convert(Image.FORMAT_RGBA8)
			var cut := Rect2i(290, 811, 310, 8) if row == 1 else Rect2i(0, 811, 290, 8)
			pixels.fill_rect(cut, Color.TRANSPARENT)
			atlas_texture = ImageTexture.create_from_image(pixels)
		sprite.texture = atlas_texture
		sprite.region_enabled = true
		sprite.region_filter_clip_enabled = true
		# Scale is derived once from idle anatomy; never resized for attack pose.
		var idle_rect: Rect2 = regions[0]
		var idle_foot: Vector2 = feet[0]
		base_scale = Vector2.ONE * sprite_height / (idle_foot.y - idle_rect.position.y)
		sprite.scale = base_scale
		set_pose(0)
		_start_idle_breath()
	elapsed = float(unit.id) * 1.7
	queue_redraw()

func sync(data: Dictionary) -> void:
	var was_alive: bool = bool(unit.get("alive", true))
	unit = data.duplicate(true)
	if not bool(unit.alive):
		if hurt_tween != null: hurt_tween.kill()
		if rotation_tween != null: rotation_tween.kill()
		if pulse_tween != null: pulse_tween.kill()
		if idle_tween != null: idle_tween.kill()
		sprite.rotation = 0.0
		if was_alive:
			if death_tween != null: death_tween.kill()
			death_tween = create_tween().set_parallel(true)
			death_tween.tween_property(sprite, "modulate", Color(0.45,0.46,0.6,0.35), .35)
			death_tween.tween_property(sprite, "scale", base_scale*0.85, .35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			death_tween.tween_property(sprite, "rotation", -.14 if int(unit.team)==0 else .14, .35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			death_tween.tween_property(sprite, "position:y", pose_base.y+10.0, .35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	elif not was_alive:
		if death_tween != null: death_tween.kill()
		sprite.modulate = Color.WHITE
		sprite.rotation = 0.0
		sprite.scale = base_scale
		_start_idle_breath()
	queue_redraw()

func set_pose(value: int) -> void:
	pose = clampi(value, 0, 1)
	if atlas_texture != null:
		var rect: Rect2 = regions[pose]
		var foot: Vector2 = feet[pose]
		sprite.region_rect = rect
		pose_base = (rect.position + rect.size * 0.5 - foot) * base_scale
		sprite.position = pose_base

func _process(delta: float) -> void:
	elapsed += delta
	if not acting and bool(unit.get("alive", true)) and sprite != null:
		sprite.position = pose_base
		if rotation_tween == null or not rotation_tween.is_running():
			sprite.rotation = 0.0
	if active or selected:
		queue_redraw()

func _draw() -> void:
	if unit.is_empty():
		return
	var alive := bool(unit.get("alive", true))
	draw_set_transform(Vector2(0, -4),0,Vector2(1,.25))
	draw_circle(Vector2.ZERO,49,Color(0.01,.015,.035,.5 if alive else .2))
	if selected and alive:
		draw_arc(Vector2.ZERO,58,0,TAU,70,Color(1,.77,.38,.9),3,true)
	if active and alive:
		draw_arc(Vector2.ZERO,64,elapsed,elapsed+TAU*.82,65,Color(.4,.91,1,.75),2,true)
	draw_set_transform(Vector2.ZERO)
	if alive and int(unit.get("shield",0))>0:
		var shell:=PackedVector2Array()
		for i in range(49):
			var a:=PI*.92+i*PI*1.16/48
			shell.append(Vector2(cos(a)*84,-sprite_height*.48+sin(a)*sprite_height*.52))
		draw_polyline(shell,Color(.45,.82,1,.34),2,true)
	health_layer.queue_redraw()

func _draw_health() -> void:
	if unit.is_empty():return
	var y := -sprite_height - 35
	var health := float(unit.hp) / maxf(1,float(unit.max_hp))
	health_layer.draw_style_box(_panel(Color(.025,.04,.07,.9),6),Rect2(-58,y,116,34))
	var ink := Color(.8,.91,.97) if int(unit.team)==0 else Color(1,.79,.7)
	var name_text := str(unit.name)
	health_layer.draw_string(font,Vector2(-font.get_string_size(name_text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x/2,y+14),name_text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,ink)
	health_layer.draw_rect(Rect2(-50,y+21,100,5),Color(.1,.16,.23))
	var bar := Color(.3,.85,.72) if int(unit.team)==0 else Color(.9,.37,.38)
	if hurt_pulse>0.0:bar=bar.lerp(Color(1,.22,.18),hurt_pulse)
	health_layer.draw_rect(Rect2(-50,y+21,100*health,5),bar)
	if int(unit.get("shield",0))>0:
		health_layer.draw_rect(Rect2(-50,y+28,minf(100,float(unit.shield)/float(unit.max_hp)*100),3),Color(.45,.77,1))
	var tags := ""
	if int(unit.get("stun",0))>0: tags += "禁锢 "
	if int(unit.get("burn",0))>0: tags += "灼烧 "
	if bool(unit.get("charging",false)): tags += "蓄力 · 可打断"
	if bool(unit.get("enraged",false)): tags += " 狂暴"
	if not tags.is_empty():
		health_layer.draw_string(font,Vector2(-50,y-7),tags,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(1,.7,.32))

func _panel(color: Color, radius: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color=color
	b.set_corner_radius_all(radius)
	return b

func hit_test(point: Vector2) -> bool:
	return bool(unit.get("alive",false)) and Rect2(global_position+Vector2(-65,-sprite_height+35),Vector2(130,sprite_height-20)).has_point(point)

func strike(target: Vector2, melee: bool) -> void:
	acting=true
	_stop_idle_breath()
	var direction := 1.0 if int(unit.team)==0 else -1.0
	var t := create_tween()
	t.tween_property(self,"position",home+Vector2(-12*direction,0),.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if melee:
		t.tween_property(self,"position",target+Vector2(-100*direction,0),.08).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	else:
		t.tween_property(sprite,"position:y",pose_base.y-12,.08).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	await t.finished
	set_pose(1)

func return_home() -> void:
	set_pose(0)
	var t := create_tween().set_parallel(true)
	t.tween_property(self,"position",home,.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(sprite,"position",pose_base,.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await t.finished
	set_pose(0)
	acting=false
	_start_idle_breath()

func hurt() -> void:
	if not bool(unit.get("alive", false)):
		return
	if hurt_tween != null: hurt_tween.kill()
	if jitter_tween != null: jitter_tween.kill()
	if pulse_tween != null: pulse_tween.kill()
	hurt_tween = create_tween()
	hurt_tween.tween_property(sprite,"modulate",Color(8,4,4),.05)
	hurt_tween.tween_property(sprite,"modulate",Color.WHITE,.12)
	var base: Vector2 = position
	jitter_tween = create_tween()
	for i in range(3):
		jitter_tween.tween_property(self,"position",base+Vector2.from_angle(randf()*TAU)*3.0,.05)
	jitter_tween.tween_property(self,"position",base,.05)
	pulse_tween = create_tween()
	pulse_tween.tween_method(_set_hurt_pulse,1.0,0.0,.18)

func _set_hurt_pulse(value: float) -> void:
	hurt_pulse=value
	health_layer.queue_redraw()

func _start_idle_breath() -> void:
	if sprite==null:return
	if idle_tween != null: idle_tween.kill()
	sprite.scale=base_scale
	idle_tween=create_tween().set_loops()
	idle_tween.tween_property(sprite,"scale:y",base_scale.y*1.015,1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	idle_tween.tween_property(sprite,"scale:y",base_scale.y,1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _stop_idle_breath() -> void:
	if idle_tween != null: idle_tween.kill()
	idle_tween=null
	if sprite!=null:sprite.scale=base_scale
