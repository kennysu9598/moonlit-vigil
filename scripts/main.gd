extends Node2D

const Combat = preload("res://scripts/combat.gd")
const Actor = preload("res://scripts/actor.gd")
const Effects = preload("res://scripts/effects.gd")
const AI = preload("res://scripts/auto_policy.gd")
const Seal = preload("res://scripts/skill_seal.gd")
const Cinematic = preload("res://scripts/cinematic.gd")
const Terrain = preload("res://scripts/terrain_fx.gd")
var FACE: FontVariation
const HOMES = [Vector2(270,435),Vector2(145,550),Vector2(385,550),Vector2(970,435),Vector2(1120,550),Vector2(830,560)]
const GOLD = Color("e9c68c")
const INK = Color("e8edf1")
var combat = Combat.new()
var actors: Array = []
var world: Node2D
var fx: Node2D
var ui: Control
var hud: Control
var overlay: Control
var title_label: Label
var info_label: Label
var turn_label: Label
var energy_label: Label
var target_label: Label
var skill_buttons: Array[Button] = []
var cast_button: Button
var help_label: Label
var queue_label: Label
var music: AudioStreamPlayer
var sfx: AudioStreamPlayer
var selected_skill := 0
var selected_target := 3
var busy := true
var phase := "title"
var pending: Dictionary = {}
var elapsed := 0.0
var run_number := 0
var shake_strength := 0.0
var evidence_dir := ""
var history: Array = []
var started_at := 0.0
var mute := false
var banner: Label
var sound_button: Button
var auto_button: Button
var speed_button: Button
var auto_enabled := false
var speed := 1
var auto_pending := false
var background: Sprite2D
var cinema: Node2D
var turn_icons: Array = []
var active_portrait: TextureRect
var stage: Node2D
var realm_target:=0.0
var realm_strength:=0.0
var realm_tint:=Color.WHITE
var last_kind:="slash"
var terrain: Node2D
var models: Node2D
var last_points: Array[Vector2]=[]

func _portrait(parent: Node,pos: Vector2,size_value: Vector2,id: int) -> TextureRect:
	var icon:=TextureRect.new()
	icon.position=pos
	icon.size=size_value
	icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
	icon.texture=_face_texture(id)
	parent.add_child(icon)
	return icon

func _face_texture(id: int) -> AtlasTexture:
	var texture:=AtlasTexture.new()
	texture.atlas=load("res://assets/art/heroes.png" if id<3 else "res://assets/art/enemies_v2.png")
	var crops=[Rect2(220,0,160,160),Rect2(220,412,150,150),Rect2(254,815,160,160),Rect2(165,34,185,185),Rect2(237,440,175,175),Rect2(183,810,205,205)]
	texture.region=crops[id]
	return texture

func _environment(kind: String,strength: float) -> void:
	realm_target=strength
	match kind:
		"fire","raven_fire":realm_tint=Color("ff612b")
		"heal","shield":realm_tint=Color("5fbbff")
		"boss","quake","charge","miasma":realm_tint=Color("a26bff")
		"dragon":realm_tint=Color("649bff")
		"raven":realm_tint=Color("b56cbb")
		"spirit","moonbolt":realm_tint=Color("5bdec4")
		"slash","stun":realm_tint=Color("e589ac")

func _toggle_auto() -> void:
	auto_enabled=not auto_enabled
	auto_button.text="自动 · A" if auto_enabled else "手动 · A"
	auto_button.modulate=Color("8bead6") if auto_enabled else Color.WHITE
	_log("auto_toggle",{"enabled":auto_enabled})
	if phase=="battle" and pending.is_empty():_refresh_hud();_queue_auto()

func _cycle_speed() -> void:
	speed=speed%3+1
	Engine.time_scale=float(speed) if phase=="battle" else 1.0
	speed_button.text=str(speed)+" 倍速 · S"
	_log("speed",{"value":speed})

func _queue_auto() -> void:
	if auto_pending or not auto_enabled or busy or phase!="battle" or combat.current_id>=3:return
	auto_pending=true
	var run_token:=run_number
	var action_token: int=combat.action_count
	await get_tree().create_timer(.55).timeout
	auto_pending=false
	if not auto_enabled or busy or phase!="battle" or run_token!=run_number or action_token!=combat.action_count:return
	var choice: Dictionary=AI.choose(combat)
	selected_skill=int(choice.skill)
	selected_target=int(choice.target)
	_log("auto_input",{"skill":selected_skill,"target":selected_target,"actor":combat.current_id})
	_cast(selected_skill,selected_target)

func _ready() -> void:
	FACE=FontVariation.new()
	FACE.base_font=preload("res://assets/fonts/cjk.ttf")
	FACE.variation_opentype={TextServerManager.get_primary_interface().name_to_tag("wght"):500}
	FACE.variation_embolden=0.6
	DisplayServer.window_set_title("月灯守夜 · 灵兽绘卷 v0.4")
	RenderingServer.set_default_clear_color(Color("07101c"))
	background = Sprite2D.new()
	background.texture=load("res://assets/art/shrine.png")
	background.centered=false
	background.scale=Vector2(1312.0/background.texture.get_width(),738.0/background.texture.get_height())
	background.position=Vector2(-16,-9)
	add_child(background)
	var mat:=ShaderMaterial.new()
	mat.shader=preload("res://scripts/shrine.gdshader")
	background.material=mat
	stage=Node2D.new()
	add_child(stage)
	stage.draw.connect(_draw_stage)
	terrain=Terrain.new()
	add_child(terrain)
	world=Node2D.new()
	add_child(world)
	fx=Effects.new()
	fx.font=FACE
	fx.impact.connect(_impact)
	fx.shake.connect(func(amount: float): shake_strength=amount)
	fx.environment.connect(_environment)
	add_child(fx)
	fx.z_index=80
	models=load("res://scripts/art_fx.gd").new()
	add_child(models)
	cinema=Cinematic.new()
	cinema.face=FACE
	cinema.z_index=90
	add_child(cinema)
	ui=Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.z_index=100
	add_child(ui)
	hud=Control.new()
	hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(hud)
	hud.draw.connect(_draw_hud_frames)
	_panel(hud,Rect2(20,16,1240,66),Color(.035,.055,.09,.93))
	_label(hud,"月灯守夜",Vector2(40,24),Vector2(180,30),24,GOLD)
	_label(hud,"灵兽绘卷  /  荒祟渡夜",Vector2(42,55),Vector2(200,20),11,Color("9bafb9"))
	turn_label=_label(hud,"",Vector2(245,27),Vector2(310,28),19,INK)
	queue_label=_label(hud,"",Vector2(245,57),Vector2(600,20),13,Color("b1c3cc"))
	energy_label=_label(hud,"",Vector2(565,27),Vector2(265,34),18,GOLD)
	auto_button=_button(hud,"手动 · A",Rect2(860,30,130,36),16)
	auto_button.pressed.connect(_toggle_auto)
	speed_button=_button(hud,"1 倍速 · S",Rect2(1000,30,124,36),15)
	speed_button.pressed.connect(_cycle_speed)
	sound_button = _button(hud,"声音 · 开",Rect2(1135,30,100,36),14)
	sound_button.pressed.connect(_toggle_mute)
	_panel(hud,Rect2(20,583,1240,120),Color(.025,.04,.07,.92))
	active_portrait=_portrait(hud,Vector2(38,594),Vector2(76,90),0)
	info_label=_label(hud,"",Vector2(135,591),Vector2(360,28),21,GOLD)
	target_label=_label(hud,"",Vector2(135,625),Vector2(390,45),15,INK)
	for i in range(3):
		var b := Seal.new()
		b.position=Vector2(615+i*140,585)
		b.size=Vector2(140,112)
		b.face=FACE
		hud.add_child(b)
		b.pressed.connect(_choose_skill.bind(i))
		skill_buttons.append(b)
	cast_button=_button(hud,"施放  ↵",Rect2(1065,615,165,58),20)
	cast_button.pressed.connect(_player_cast)
	help_label=_label(hud,"",Vector2(135,678),Vector2(480,22),13,Color("bfd0da"))
	for id in range(6):
		var icon:=_portrait(hud,Vector2(456+id*61,101),Vector2(44,44),id)
		turn_icons.append(icon)
	banner=_label(ui,"",Vector2(310,105),Vector2(660,58),34,GOLD)
	banner.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_color_override("font_shadow_color",Color.BLACK)
	banner.add_theme_constant_override("shadow_offset_x",3)
	banner.add_theme_constant_override("shadow_offset_y",3)
	music=AudioStreamPlayer.new()
	add_child(music)
	var ambience=load("res://assets/audio/moon_ambience_loop.wav") as AudioStreamWAV
	ambience.loop_mode=AudioStreamWAV.LOOP_FORWARD
	ambience.loop_end=529200
	music.stream=ambience
	music.volume_db=-18
	music.play()
	sfx=AudioStreamPlayer.new()
	add_child(sfx)
	sfx.volume_db=-10
	var stamp := Time.get_datetime_string_from_system().replace(":","-")
	var folder := "user://battle-evidence/"+stamp
	evidence_dir=ProjectSettings.globalize_path(folder)
	DirAccess.make_dir_recursive_absolute(evidence_dir)
	_show_title()
	if "--autoexit" in OS.get_cmdline_user_args():
		get_tree().create_timer(1800.0,true,false,true).timeout.connect(func(): _save_history();get_tree().quit())

func _panel(parent: Node, rect: Rect2, color: Color) -> Panel:
	var p := Panel.new()
	p.position=rect.position
	p.size=rect.size
	p.mouse_filter=Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel",_style(color,Color(.7,.63,.45,.3)))
	parent.add_child(p)
	return p

func _style(color: Color, border: Color) -> StyleBoxFlat:
	var s:=StyleBoxFlat.new()
	s.bg_color=color
	s.border_color=border
	s.set_border_width_all(1)
	s.set_corner_radius_all(8)
	return s

func _label(parent: Node, text: String, pos: Vector2, size_value: Vector2, font_size: int, color: Color) -> Label:
	var l:=Label.new()
	l.text=text
	l.position=pos
	l.size=size_value
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_override("font",FACE)
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	parent.add_child(l)
	return l

func _button(parent: Node, text: String, rect: Rect2, font_size: int) -> Button:
	var b:=Button.new()
	b.focus_mode=Control.FOCUS_NONE
	b.text=text
	b.position=rect.position
	b.size=rect.size
	b.add_theme_font_override("font",FACE)
	b.add_theme_font_size_override("font_size",font_size)
	b.add_theme_color_override("font_color",INK)
	b.add_theme_stylebox_override("normal",_style(Color("132331"),Color("586166")))
	b.add_theme_stylebox_override("hover",_style(Color("263f4a"),GOLD))
	b.add_theme_stylebox_override("pressed",_style(Color("365665"),GOLD))
	b.add_theme_stylebox_override("disabled",_style(Color("111b26"),Color("333c49")))
	b.add_theme_color_override("font_disabled_color",Color("657381"))
	parent.add_child(b)
	return b

func _show_title() -> void:
	hud.hide()
	overlay=Control.new()
	ui.add_child(overlay)
	_panel(overlay,Rect2(330,140,620,460),Color(.025,.045,.08,.94))
	_label(overlay,"MOONLIT VIGIL",Vector2(385,167),Vector2(510,30),16,Color("a8bdc4"))
	_label(overlay,"月灯守夜",Vector2(385,211),Vector2(510,70),52,GOLD)
	_label(overlay,"月蚀将至，荒祟率妖群踏过山门。\n三位守夜人须在灯火熄灭前，守住最后一座神社。",Vector2(385,306),Vector2(510,64),18,INK)
	_label(overlay,"3 位守夜人  ·  共享灵火  ·  一场完整战斗\n绯羽主攻 · 澄铃疗愈 · 玄刃打断首领蓄力",Vector2(385,387),Vector2(510,56),16,Color("a8bdc4"))
	var b:=_button(overlay,"点灯 · 开始战斗",Rect2(385,473,510,60),23)
	b.pressed.connect(_start_battle)
	_label(overlay,"1–3 技能 · Tab 目标 · Enter 施放 · A 自动 · S 倍速",Vector2(385,550),Vector2(540,24),13,Color("b5c3cb"))

func _start_battle() -> void:
	if overlay!=null: overlay.queue_free();overlay=null
	fx.reset()
	models.reset()
	terrain.reset()
	Engine.time_scale=float(speed)
	realm_strength=0;realm_target=0
	for actor in actors: actor.queue_free()
	actors.clear()
	combat.start(42)
	history=[]
	run_number+=1
	started_at=Time.get_ticks_msec()/1000.0
	var hero=load("res://assets/art/heroes.png")
	var enemy=load("res://assets/art/enemies_v2.png")
	for unit in combat.units:
		var actor=Actor.new()
		world.add_child(actor)
		actor.setup(unit,FACE,hero if unit.id<3 else enemy,int(unit.id)%3)
		actor.home=HOMES[unit.id]
		actor.position=actor.home
		actor.z_index=10+int(actor.home.y/20)
		actors.append(actor)
	phase="battle"
	var battle_track=load("res://assets/audio/battle_theme.ogg") as AudioStreamOggVorbis
	battle_track.loop=true
	music.stream=battle_track
	music.volume_db=-14
	music.play()
	music.stream_paused=mute
	hud.show()
	_sound("ui_confirm")
	_log("battle_start",{"run":run_number,"seed":42})
	_next_turn()

func _next_turn() -> void:
	busy=true
	var begin: Dictionary=combat.begin_turn()
	for actor in actors: actor.active=false; actor.selected=false;actor.queue_redraw()
	_show_events(begin.events)
	_sync(begin.units)
	_log("turn",begin)
	if combat.winner!=-1: _finish();return
	if begin.skipped:
		banner.text=str(combat.units[combat.current_id].name)+" · 无法行动"
		await get_tree().create_timer(.7).timeout
		combat.advance()
		_next_turn()
		return
	actors[combat.current_id].active=true
	selected_skill=0
	selected_target=_default_target()
	busy=combat.current_id>=3
	banner.text=""
	_refresh_hud()
	if not busy:_queue_auto()
	if busy:
		await get_tree().create_timer(.95).timeout
		var choice: Dictionary=combat.ai_choice()
		_cast(int(choice.skill),int(choice.target))

func _default_target() -> int:
	var skill: Dictionary=combat.skills_for(combat.current_id)[selected_skill]
	var team: int=int(combat.units[combat.current_id].team)
	if skill.target in ["enemy","all_enemies"]: team=1-team
	if skill.target=="self":return combat.current_id
	var best: int=-1
	for u in combat.units:
		if u.alive and int(u.team)==team:
			if best<0:best=u.id
			elif skill.target=="ally" and float(u.hp)/u.max_hp < float(combat.units[best].hp)/combat.units[best].max_hp:best=u.id
	return best

func _choose_skill(index: int) -> void:
	if busy or auto_enabled or phase!="battle":return
	selected_skill=index
	selected_target=_default_target()
	_sound("ui_select")
	_refresh_hud()

func _player_cast() -> void:
	if busy or auto_enabled or phase!="battle":return
	_log("player_input",{"skill":selected_skill,"target":selected_target,"actor":combat.current_id})
	_cast(selected_skill,selected_target)

func _cast(skill_index: int,target: int) -> void:
	var id: int=combat.current_id
	var skill: Dictionary=combat.skills_for(id)[skill_index]
	var result: Dictionary=combat.perform(skill_index,target)
	if not result.ok:
		help_label.text=result.reason
		_sound("ui_error")
		return
	busy=true
	pending=result
	for b in skill_buttons:b.disabled=true
	cast_button.disabled=true
	cast_button.text="妖群行动中" if id>=3 else "施法中…"
	for a in actors:a.selected=false;a.queue_redraw()
	for icon in turn_icons:icon.hide()
	hud.queue_redraw()
	banner.text=str(combat.units[id].name)+"  ·  "+str(skill.name)
	var points: Array[Vector2]=[]
	var ids: Array[int]=[]
	if skill.target in ["all_enemies","all_allies"]:
		var team: int=1-int(combat.units[id].team) if skill.target=="all_enemies" else int(combat.units[id].team)
		for a in actors:
			if a.unit.alive and int(a.unit.team)==team: ids.append(int(a.unit.id))
	else:ids.append(target)
	for i in ids:points.append(actors[i].home)
	var themes: Array=[ ["slash","fire","fire"], ["moonbolt","heal","shield"], ["slash","stun","dragon"], ["raven","raven_fire","raven"], ["spirit","shield","miasma"], ["quake","charge","boss"] ]
	var kind: String=themes[id][skill_index]
	last_kind=kind
	if result.ultimate:
		_environment(kind,.65)
		var portrait_rect: Rect2=actors[id].regions[1]
		await cinema.start(actors[id].atlas_texture,portrait_rect,str(skill.name),realm_tint.lightened(.3))
	var melee: bool=skill_index==0 and id in [0,2,3,5]
	await actors[id].strike(actors[target].home,melee)
	last_points=points
	models.start(id,skill_index,actors[id].position,points,bool(result.ultimate))
	fx.modeled_primary=models.active
	await fx.play(kind,actors[id].position,points,2.0 if result.ultimate else 1.0)
	await actors[id].return_home()
	_log("action",result)
	pending={}
	banner.text=""
	if combat.winner!=-1:_finish();return
	combat.advance()
	_next_turn()

func _impact() -> void:
	if pending.is_empty():return
	terrain.hit(last_kind,last_points,bool(pending.get("ultimate",false)))
	if last_kind not in ["heal","shield"]:
		_sound("impact_heavy" if bool(pending.get("ultimate",false)) else ("impact_slash" if last_kind=="slash" else "impact_magic"))
	_show_events(pending.events)
	_sync(pending.units)
	_refresh_hud()

func _show_events(events: Array) -> void:
	for e in events:
		var id: int=int(e.get("id",0))
		if id<0 or id>=actors.size():continue
		match str(e.type):
			"damage":
				fx.floating(actors[id].position,str(e.value),Color("ffe3b8"))
				actors[id].hurt()
			"heal":fx.floating(actors[id].position,"+"+str(e.value),Color("89ffcb"));_sound("heal")
			"shield":fx.floating(actors[id].position,"护盾 +"+str(e.value),Color("87dbff"));_sound("shield")
			"stun":fx.floating(actors[id].position,"封魂",GOLD)
			"interrupt":fx.floating(actors[id].position,"蓄力打断",GOLD)
			"charge":fx.floating(actors[id].position,"厄月蓄力",Color("d69aff"))
			"enrage":fx.floating(actors[id].position,"荒祟 · 狂暴",Color("ff7777"))

func _sync(units: Array) -> void:
	for i in range(mini(units.size(),actors.size())):actors[i].sync(units[i])

func _refresh_hud() -> void:
	if combat.units.is_empty():return
	var actor: Dictionary=combat.units[combat.current_id]
	turn_label.text=("妖群行动" if actor.team==1 else "轮到 "+str(actor.name))+"  ·  第 "+str(combat.round_index)+" 轮"
	var order: PackedStringArray=[]
	for n in [0,3,2,4,1,5]:
		if combat.units[n].alive:order.append(str(combat.units[n].name))
	queue_label.text="行动顺序   "+" → ".join(order)
	energy_label.text="灵火  "+"◆".repeat(combat.energy)+"◇".repeat(8-combat.energy)
	info_label.text=str(actor.name)+(" · 妖群" if actor.team==1 else " · 守夜人")
	active_portrait.texture=_face_texture(combat.current_id)
	var visible_order: Array=[]
	var order_ids: Array=[0,3,2,4,1,5]
	var current_index: int=order_ids.find(combat.current_id)
	for step in range(6):
		var id: int=order_ids[(current_index+step)%6]
		if combat.units[id].alive:visible_order.append(id)
	for i in range(6):
		turn_icons[i].visible=i<visible_order.size() and not busy
		if i<visible_order.size():
			turn_icons[i].texture=_face_texture(visible_order[i])
			turn_icons[i].modulate=GOLD if i==0 else Color(.72,.8,.88)
	var skills: Array=combat.skills_for(combat.current_id)
	for i in range(3):
		skill_buttons[i].skill_name=str(skills[i].name)
		skill_buttons[i].cost=int(skills[i].cost)
		skill_buttons[i].hotkey=i+1
		skill_buttons[i].kind=str(skills[i].kind)
		if combat.current_id==0 and i>0:skill_buttons[i].kind="fire"
		skill_buttons[i].chosen=i==selected_skill
		skill_buttons[i].disabled=busy or auto_enabled or (actor.team==0 and combat.energy<int(skills[i].cost))
		skill_buttons[i].queue_redraw()
	cast_button.disabled=busy or auto_enabled or combat.energy<int(skills[selected_skill].cost)
	cast_button.text=("妖群行动中" if actor.team==1 else "施法中…") if busy else ("自动出招中" if auto_enabled else "施放  ↵")
	target_label.text="目标 · "+str(combat.units[selected_target].name)+"\n"+str(combat.units[selected_target].hp)+" / "+str(combat.units[selected_target].max_hp)
	help_label.text=str(skills[selected_skill].description)
	if bool(combat.units[5].get("charging",false)):
		help_label.text="⚠ 荒祟正在蓄力！玄刃的「封魂」可以打断。"
	for a in actors:a.selected=not busy and int(a.unit.id)==selected_target;a.queue_redraw()
	hud.queue_redraw()

func _finish() -> void:
	busy=true
	phase="result"
	Engine.time_scale=1.0
	realm_target=0
	for a in actors:a.active=false;a.selected=false;a.queue_redraw()
	hud.hide()
	banner.text=""
	_log("result",{"winner":combat.winner,"actions":combat.action_count,"seconds":Time.get_ticks_msec()/1000.0-started_at})
	_save_history()
	overlay=Control.new()
	ui.add_child(overlay)
	_panel(overlay,Rect2(360,180,560,370),Color(.025,.045,.075,.95))
	_label(overlay,"长夜已过" if combat.winner==0 else "灯火暂熄",Vector2(415,222),Vector2(465,66),43,GOLD)
	_label(overlay,"荒祟退散，山门的灯火仍然明亮。" if combat.winner==0 else "调整灵火分配，再一次守住山门。",Vector2(415,310),Vector2(465,40),18,INK)
	_label(overlay,"战斗结束  ·  "+str(combat.action_count)+" 次行动  ·  "+str(combat.round_index)+" 轮",Vector2(415,366),Vector2(465,32),16,Color("9cb6c1"))
	var again:=_button(overlay,"再守一夜  ·  R",Rect2(415,430,450,62),22)
	again.pressed.connect(_start_battle)
	_capture("result")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_A:_toggle_auto()
			KEY_S:_cycle_speed()
			KEY_M:_toggle_mute()
			KEY_F12:_capture("manual")
			KEY_R:
				if phase=="result":_start_battle()
			KEY_ENTER, KEY_SPACE:
				if phase=="title":_start_battle()
				elif phase=="battle":_player_cast()
			KEY_1:_choose_skill(0)
			KEY_2:_choose_skill(1)
			KEY_3:_choose_skill(2)
			KEY_TAB:
				if not busy:
					for offset in range(1,7):
						var n: int=(selected_target+offset)%6
						if actors[n].unit.alive and actors[n].unit.team==actors[selected_target].unit.team:selected_target=n;break
					_refresh_hud()
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not busy:
		for a in actors:
			if a.hit_test(get_global_mouse_position()) and a.unit.team==actors[selected_target].unit.team:
				selected_target=a.unit.id
				_sound("ui_select")
				_refresh_hud()
				break

func _toggle_mute() -> void:
	mute=not mute
	sound_button.text="声音 · 关" if mute else "声音 · 开"
	music.stream_paused=mute
	sfx.volume_db=-80 if mute else -10

func _sound(name_value: String) -> void:
	if mute:return
	sfx.stream=load("res://assets/audio/"+name_value+".ogg")
	sfx.play()

func _process(delta: float) -> void:
	elapsed+=delta
	shake_strength=move_toward(shake_strength,0,delta*28)
	world.position=Vector2(sin(elapsed*89),cos(elapsed*97))*shake_strength
	background.position=Vector2(-16,-9)+world.position*.65
	stage.position=world.position*.65
	terrain.position=world.position
	realm_strength=move_toward(realm_strength,realm_target,delta*4)
	background.material.set_shader_parameter("realm",realm_strength)
	background.material.set_shader_parameter("realm_tint",realm_tint)
	background.material.set_shader_parameter("clock",elapsed)
	background.material.set_shader_parameter("shock",terrain.shock)
	background.material.set_shader_parameter("impact_point",terrain.point)
	stage.queue_redraw()

func _draw_stage() -> void:
	for i in range(34):
		var p:=Vector2(fposmod(float(i*137)+sin(elapsed*.15+i)*30,1280),fposmod(float(i*87)-elapsed*(3+i%4),650))
		stage.draw_circle(p,1.2,Color(.7,.92,1,(sin(elapsed+i)+1)*.16))
	for i in range(12):
		var p:=Vector2(fposmod(i*179+elapsed*18,1380)-50,fposmod(i*91+elapsed*12,540)+80)
		stage.draw_set_transform(p,sin(elapsed+i)*.8)
		stage.draw_colored_polygon(PackedVector2Array([Vector2(-4,0),Vector2(0,-3),Vector2(6,0),Vector2(0,3)]),Color(.72,.25,.29,.4))
	stage.draw_set_transform(Vector2.ZERO)

func _log(kind: String,data: Dictionary) -> void:
	history.append({"type":kind,"time":Time.get_datetime_string_from_system(),"data":data.duplicate(true)})
	_save_history()

func _save_history() -> void:
	var f:=FileAccess.open(evidence_dir+"/run_"+str(run_number)+".json",FileAccess.WRITE)
	if f!=null:f.store_string(JSON.stringify({"game":"月灯守夜","version":"20260915T165800","history":history},"\t"))

func _draw_hud_frames() -> void:
	if busy:return
	for i in range(turn_icons.size()):
		if turn_icons[i].visible:
			var p: Vector2=turn_icons[i].position+Vector2(22,22)
			hud.draw_circle(p,26,Color(.035,.055,.08,.92))
			hud.draw_arc(p,26,0,TAU,48,GOLD if i==0 else Color(.4,.47,.52),2 if i==0 else 1,true)

func _capture(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var path:=evidence_dir+"/"+tag+"_"+str(Time.get_ticks_msec())+".png"
	get_viewport().get_texture().get_image().save_png(path)
	print("SCREENSHOT "+path)
