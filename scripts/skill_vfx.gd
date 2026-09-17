class_name SkillVfx
extends Node2D
# v0.6.0 skill VFX library: 18 skills (6 units x 3 skills), shield state visuals
# and the boss charge warning trio. Timeline per R7: T1 0.60s/peak 0.18,
# T2 0.86s/peak 0.40, T3 2.80s/peak 1.55.
# Iron rule: additive flash, white cores and vignette live ONLY on this
# independent layer. Never modulate actor sprites or the art_fx painted mesh.

signal shake(amount: float)

const WINDUP: Array[float] = [0.06, 0.09, 0.14]
const PEAKS: Array[float] = [0.18, 0.40, 1.55]
const SCREEN := Rect2(0, 0, 1280, 720)
const VIGNETTE_INK := Color("110c26")
const CHARGE_COLOR := Color("bb82ff")
const CHARGE_GLOW := Color("e6d2ff")

# Per-skill parameters frozen from the R7 design table. Keyed "u<unit>s<slot>".
# c=main color, hi=highlight, tele=telegraph shape, tr=[from_radius,to_radius],
# k=fullscreen flash strength, white=target white core flash, burst=particle
# recipe, vig=vignette spike at impact, arena=T3 charge-phase set piece.
const SPECS := {
	"u0s0": {"c": Color("ff733d"), "hi": Color("ffdc7c"), "tele": "sigil", "tr": [12.0, 40.0], "k": 0.14, "white": true, "burst": "burst"},
	"u0s1": {"c": Color("ff733d"), "hi": Color("ffdc7c"), "tele": "ground_sigils", "tr": [26.0, 62.0], "k": 0.20, "white": true, "burst": "embers_fire"},
	"u0s2": {"c": Color("ff733d"), "hi": Color("ffe6a0"), "tele": "none", "tr": [26.0, 62.0], "k": 0.23, "white": false, "burst": "after_embers", "vig": 0.45, "arena": "ring_charge"},
	"u1s0": {"c": Color("8fdfff"), "hi": Color("f2ffff"), "tele": "double_ring", "tr": [18.0, 44.0], "k": 0.10, "white": true, "burst": "chime"},
	"u1s1": {"c": Color("79ffd2"), "hi": Color("b9ffe9"), "tele": "ground_sigil", "tr": [20.0, 68.0], "k": 0.12, "white": true, "burst": "up_heal"},
	"u1s2": {"c": Color("8fdfff"), "hi": Color("79ffd2"), "tele": "none", "tr": [20.0, 68.0], "k": 0.16, "white": false, "burst": "barrier_dust", "vig": 0.35},
	"u2s0": {"c": Color("7fa9ff"), "hi": Color("dce9ff"), "tele": "fan", "tr": [10.0, 46.0], "k": 0.12, "white": true, "burst": ""},
	"u2s1": {"c": Color("7fa9ff"), "hi": Color("dce9ff"), "tele": "ground_sigil", "tr": [26.0, 70.0], "k": 0.16, "white": true, "burst": "sigil_spark"},
	"u2s2": {"c": Color("7fa9ff"), "hi": Color("dce9ff"), "tele": "none", "tr": [26.0, 70.0], "k": 0.22, "white": true, "burst": "break_slash", "vig": 0.40},
	"u3s0": {"c": Color("cc5277"), "hi": Color("2a0e1c"), "tele": "ring_collapse", "tr": [34.0, 20.0], "k": 0.12, "white": true, "burst": "drop_streak", "vig": 0.15},
	"u3s1": {"c": Color("cc5277"), "hi": Color("2a0e1c"), "tele": "ring_breathe", "tr": [26.0, 70.0], "k": 0.18, "white": true, "burst": "black_flame", "vig": 0.25},
	"u3s2": {"c": Color("cc5277"), "hi": Color("bda1f0"), "tele": "none", "tr": [26.0, 70.0], "k": 0.20, "white": false, "burst": "crow_embers", "vig": 0.45, "arena": "crows"},
	"u4s0": {"c": Color("ffd98a"), "hi": Color("fff3c4"), "tele": "ring_collapse", "tr": [30.0, 20.0], "k": 0.12, "white": true, "burst": "lantern"},
	"u4s1": {"c": Color("ffd98a"), "hi": Color("fff3c4"), "tele": "ground_sigil", "tr": [20.0, 68.0], "k": 0.12, "white": true, "burst": ""},
	"u4s2": {"c": Color("b672dd"), "hi": Color("ffd98a"), "tele": "none", "tr": [20.0, 68.0], "k": 0.18, "white": false, "burst": "lantern_embers", "vig": 0.55, "arena": "mist"},
	"u5s0": {"c": Color("bb82ff"), "hi": Color("110c26"), "tele": "ring_collapse", "tr": [36.0, 20.0], "k": 0.14, "white": true, "burst": "claw_rake", "vig": 0.15},
	"u5s1": {"c": Color("bb82ff"), "hi": Color("110c26"), "tele": "none", "tr": [150.0, 220.0], "k": 0.10, "white": false, "burst": ""},
	"u5s2": {"c": Color("bb82ff"), "hi": Color("110c26"), "tele": "none", "tr": [150.0, 220.0], "k": 0.28, "white": true, "burst": "quake_streak", "vig": 0.45},
}

class AddLayer extends Node2D:
	var host: SkillVfx
	func _init() -> void:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat
	func _draw() -> void:
		if host != null:
			host.draw_add(self)

var font: Font
var add_layer: AddLayer
var clock := 0.0
var casts: Array[Dictionary] = []
var flashes: Array[Dictionary] = []
var circles: Array[Dictionary] = []
var accents: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var shields: Array[Dictionary] = []
var arena_nodes: Array[CPUParticles2D] = []
var charge_active := false
var charge_pos := Vector2.ZERO
var charge_age := 0.0
var charge_node: CPUParticles2D
var vig_base := 0.0
var vig_pulse := 0.0

static func windup_for(tier: int) -> float:
	return WINDUP[clampi(tier, 0, 2)]

static func peak_for(tier: int) -> float:
	return PEAKS[clampi(tier, 0, 2)]

static func freeze_for(unit: int, slot: int) -> float:
	if slot != 2:
		return 0.0
	match unit:
		3: return 0.08
		0, 2, 4, 5: return 0.10
	return 0.0

func _ready() -> void:
	z_index = 84
	add_layer = AddLayer.new()
	add_layer.host = self
	add_child(add_layer)

func reset() -> void:
	casts.clear()
	flashes.clear()
	circles.clear()
	accents.clear()
	rings.clear()
	shields.clear()
	_stop_arena()
	charge_active = false
	charge_node = null
	vig_base = 0.0
	vig_pulse = 0.0
	queue_redraw()
	if add_layer != null:
		add_layer.queue_redraw()
	_sync_processing()

# --- public wiring -----------------------------------------------------------

func play_skill(unit: int, slot: int, kind: String, origin: Vector2, targets: Array[Vector2], tier: int) -> void:
	var spec: Dictionary = SPECS.get("u%ds%d" % [unit, slot], _fallback_spec(kind))
	if unit == 5 and slot == 1:
		begin_boss_charge(origin)
	elif unit == 5 and slot == 2:
		release_boss_charge(origin)
	casts.append({"spec": spec, "unit": unit, "slot": slot, "kind": kind, "origin": origin,
		"targets": targets.duplicate(), "tier": clampi(tier, 0, 2), "age": 0.0,
		"peak": peak_for(tier), "fired": false})
	match str(spec.get("arena", "")):
		"ring_charge":
			_arena_ring(origin, spec)
		"mist":
			_arena_mist(spec)
	_sync_processing()

func on_impact(ultimate: bool, points: Array[Vector2]) -> void:
	for cast in casts:
		if bool(cast.fired):
			continue
		cast.fired = true
		var spec: Dictionary = cast.spec
		var c: Color = spec.get("c", Color.WHITE)
		var k: float = float(spec.get("k", 0.0))
		if k > 0.0:
			flashes.append({"c": c, "k": k, "age": 0.0})
		if bool(spec.get("white", false)):
			var pts: Array = points if not points.is_empty() else [cast.origin]
			for p in pts:
				circles.append({"p": p + Vector2(0, -95), "age": 0.0})
		var burst: String = str(spec.get("burst", ""))
		if burst != "":
			var targets: Array = points if not points.is_empty() else [cast.origin]
			for p in targets:
				_spawn(burst, p, c, spec)
		if ultimate:
			vig_pulse = maxf(vig_pulse, float(spec.get("vig", 0.0)))
			if int(cast.unit) == 1:
				shake.emit(9.0)
			if int(cast.unit) == 2:
				for p in (points if not points.is_empty() else [cast.origin]):
					accents.append({"kind": "slash2", "p": p, "age": -0.15, "c": Color("dce9ff")})
	_stop_arena()
	queue_redraw()
	if add_layer != null:
		add_layer.queue_redraw()
	_sync_processing()

func interrupt_flash(pos: Vector2) -> void:
	flashes.append({"c": Color("ffce72"), "k": 0.30, "age": 0.0})
	circles.append({"p": pos + Vector2(0, -95), "age": 0.0})
	accents.append({"kind": "sigil_pop", "p": pos, "age": 0.0, "c": Color("ffce72")})
	shake.emit(6.0)
	_sync_processing()

func shield_gain(pos: Vector2, team: int) -> void:
	rings.append({"p": pos + Vector2(0, -95), "age": 0.0,
		"c": Color("8fdfff") if team == 0 else Color("ffd98a")})
	_sync_processing()

func shield_break_burst(pos: Vector2) -> void:
	_spawn("shield_break", pos, Color("8fdfff"), {})
	_sync_processing()

func begin_boss_charge(pos: Vector2) -> void:
	if charge_active:
		return
	charge_active = true
	charge_pos = pos
	charge_age = 0.0
	charge_node = _summon_circle(pos)
	_sync_processing()

func release_boss_charge(pos: Vector2) -> void:
	if charge_active:
		charge_pos = pos
		if charge_node != null and is_instance_valid(charge_node):
			charge_node.emitting = false
			charge_node.restart()
			_expire(charge_node, 2.0)
		charge_node = null
	charge_active = false
	_sync_processing()

func update_shields(list: Array) -> void:
	shields.clear()
	for entry in list:
		shields.append(entry)
	_sync_processing()

# --- per-frame ---------------------------------------------------------------

func _process(delta: float) -> void:
	clock += delta
	for cast in casts:
		cast.age += delta
		var spec: Dictionary = cast.spec
		var peak: float = cast.peak
		if not bool(cast.fired) and int(cast.tier) == 2:
			var ramp: float = clampf((cast.age - peak * 0.55) / (peak * 0.45), 0.0, 1.0)
			vig_pulse = maxf(vig_pulse, float(spec.get("vig", 0.0)) * ramp)
	casts = casts.filter(func(f: Dictionary) -> bool: return not bool(f.fired) or f.age < f.peak + 0.7)
	for f in flashes: f.age += delta
	flashes = flashes.filter(func(f: Dictionary) -> bool: return f.age < 0.30)
	for f in circles: f.age += delta
	circles = circles.filter(func(f: Dictionary) -> bool: return f.age < 0.32)
	for f in accents: f.age += delta
	accents = accents.filter(func(f: Dictionary) -> bool: return f.age < 0.55)
	for f in rings: f.age += delta
	rings = rings.filter(func(f: Dictionary) -> bool: return f.age < 0.42)
	if charge_active:
		charge_age += delta
		vig_base = move_toward(vig_base, 0.45, delta * 0.225)
	else:
		vig_base = move_toward(vig_base, 0.0, delta * 1.6)
	vig_pulse *= exp(-delta * 2.0)
	queue_redraw()
	if add_layer != null:
		add_layer.queue_redraw()
	_sync_processing()

func _sync_processing() -> void:
	var live: bool = not casts.is_empty() or not flashes.is_empty() or not circles.is_empty() \
		or not accents.is_empty() or not rings.is_empty() or not shields.is_empty() \
		or charge_active or vig_base > 0.005 or vig_pulse > 0.005
	set_process(live)
	if not live:
		queue_redraw()
		if add_layer != null:
			add_layer.queue_redraw()

# --- drawing (normal blend) --------------------------------------------------

func _draw() -> void:
	for cast in casts:
		_draw_cast(cast)
	if charge_active:
		_draw_charge_array()
		_draw_charge_bar()
	for s in shields:
		_draw_barrier(s)
	for f in accents:
		_draw_accent(f)
	var vig: float = clampf(vig_base + vig_pulse, 0.0, 0.85)
	if vig > 0.004:
		_draw_vignette(vig)

func _draw_cast(cast: Dictionary) -> void:
	var spec: Dictionary = cast.spec
	var c: Color = spec.get("c", Color.WHITE)
	var hi: Color = spec.get("hi", c)
	var peak: float = cast.peak
	var age: float = cast.age
	var origin: Vector2 = cast.origin
	var targets: Array = cast.targets
	if age >= peak:
		return
	var prog: float = clampf(age / peak, 0.0, 1.0)
	var rise: float = sin(prog * PI)
	match str(spec.get("tele", "none")):
		"sigil":
			_sigil(origin + Vector2(0, -100), lerpf(float(spec.tr[0]), float(spec.tr[1]), prog), age * 2.0, c, rise * 0.8)
		"double_ring":
			var p: Vector2 = origin + Vector2(0, -100)
			var r: float = lerpf(float(spec.tr[0]), float(spec.tr[1]), prog)
			draw_arc(p, r, 0, TAU, 48, _ink(c, rise * 0.8), 1.5, true)
			draw_arc(p, r * 0.62, 0, TAU, 40, _ink(hi, rise * 0.55), 1.0, true)
			for i in range(8):
				var a: float = i * TAU / 8.0 - age * 2.2
				draw_line(p + Vector2.from_angle(a) * (r - 6), p + Vector2.from_angle(a) * (r + 6), _ink(c, rise * 0.7), 1.5, true)
		"ground_sigil", "ground_sigils":
			var spots: Array = targets if str(spec.tele) == "ground_sigils" else targets.slice(0, 1)
			for tp in spots:
				_ground_sigil(tp, lerpf(float(spec.tr[0]), float(spec.tr[1]), prog), age * 1.6, c, rise * 0.75)
		"ring_collapse":
			for tp in targets:
				var r: float = lerpf(float(spec.tr[0]), float(spec.tr[1]), prog)
				draw_set_transform(tp, 0.0, Vector2(1.0, 0.35))
				draw_arc(Vector2.ZERO, r, 0, TAU, 44, _ink(c, prog * 0.9), 1.5, true)
				draw_arc(Vector2.ZERO, r * 0.55, 0, TAU, 36, _ink(hi, prog * 0.45), 1.0, true)
				draw_set_transform(Vector2.ZERO)
		"ring_breathe":
			for tp in targets:
				var r: float = lerpf(float(spec.tr[0]), float(spec.tr[1]), prog) + sin(age * TAU / 0.43) * 8.0
				draw_set_transform(tp, 0.0, Vector2(1.0, 0.35))
				draw_arc(Vector2.ZERO, r, 0, TAU, 48, _ink(c, rise * 0.85), 2.0, true)
				draw_set_transform(Vector2.ZERO)
		"fan":
			if not targets.is_empty() and prog < 0.5:
				var dirv: Vector2 = (targets[0] - origin).normalized()
				for j in range(3):
					var sweep: Vector2 = dirv.rotated((-0.28 + j * 0.28) * (1.0 - prog * 2.0))
					draw_line(origin + Vector2(0, -100), origin + Vector2(0, -100) + sweep * (60.0 + prog * 160.0), _ink(hi, (1.0 - prog * 2.0) * 0.6), 2.0, true)
	# T3 charge-phase set pieces.
	if int(cast.tier) == 2:
		var build: float = smoothstep(0.0, 0.95, age)
		match str(spec.get("arena", "")):
			"crows":
				var center: Vector2 = origin
				if not targets.is_empty():
					center = Vector2.ZERO
					for tp in targets: center += tp
					center /= targets.size()
				for i in range(14):
					var a: float = i * 2.399 + age * 1.35
					var q: Vector2 = center + Vector2(cos(a) * 250.0, sin(a) * 105.0) * build + Vector2(0, -120)
					var flap: float = sin(age * 9.0 + i * 1.7) * 9.0
					var wing := PackedVector2Array([q + Vector2(-15.0, flap), q, q + Vector2(15.0, flap)])
					draw_polyline(wing, _ink(c, build * 0.7), 2.0, true)
					draw_circle(q, 2.5, _ink(hi.lightened(0.3), build * 0.5), true, -1, true)

func _draw_charge_array() -> void:
	var pulse: float = 0.5 + 0.5 * sin(charge_age * TAU / 1.2)
	var r: float = lerpf(150.0, 220.0, pulse)
	var c := CHARGE_COLOR
	draw_set_transform(charge_pos, 0.0, Vector2(1.0, 0.38))
	draw_arc(Vector2.ZERO, r, 0, TAU, 64, _ink(c, 0.40 + 0.22 * pulse), 2.0, true)
	draw_arc(Vector2.ZERO, r * 0.74, 0, TAU, 52, _ink(CHARGE_GLOW, 0.28 + 0.18 * (1.0 - pulse)), 1.5, true)
	for i in range(8):
		var a: float = i * TAU / 8.0 + charge_age * 0.5
		var v := Vector2.from_angle(a)
		draw_line(v * (r - 9.0), v * (r + 9.0), _ink(c, 0.55), 2.0, true)
	draw_set_transform(Vector2.ZERO)

func _draw_charge_bar() -> void:
	if font == null:
		return
	var text := "⚠ 厄月坠 · 蓄力中 —— 可被眩晕打断"
	draw_string(font, Vector2(478, 88), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, _ink(Color("d69aff"), 0.95))
	var track := Rect2(478, 95, 324, 10)
	draw_rect(track, Color(0.07, 0.05, 0.15, 0.85))
	var fill_w: float = track.size.x * (0.38 + 0.30 * sin(charge_age * 2.6))
	draw_rect(Rect2(track.position, Vector2(fill_w, track.size.y)), _ink(CHARGE_COLOR, 0.9))
	draw_rect(track, _ink(CHARGE_COLOR, 0.8), false, 1.5)

func _draw_barrier(s: Dictionary) -> void:
	if int(s.get("shield", 0)) <= 0 or not bool(s.get("alive", false)):
		return
	var c: Color = Color("8fdfff") if int(s.get("team", 0)) == 0 else Color("ffd98a")
	var a: float = 0.22 + 0.08 * sin(clock * 2.4 + float(s.get("pos", Vector2.ZERO).x))
	var base: Vector2 = s.get("pos", Vector2.ZERO)
	var dome := PackedVector2Array()
	for i in range(33):
		var ang: float = PI + i * PI / 32.0
		dome.append(base + Vector2(-cos(ang) * 64.0, -96.0 + sin(ang) * 60.0))
	draw_polyline(dome, _ink(c, a), 2.0, true)
	var inner := PackedVector2Array()
	for i in range(25):
		var ang: float = PI + i * PI / 24.0
		inner.append(base + Vector2(-cos(ang) * 48.0, -96.0 + sin(ang) * 44.0))
	draw_polyline(inner, _ink(c, a * 0.6), 1.2, true)

func _draw_accent(f: Dictionary) -> void:
	var age: float = f.age
	if age < 0.0:
		return
	var p: Vector2 = f.p
	var c: Color = f.c
	var life_alpha: float = exp(-age * 9.0)
	match str(f.kind):
		"drop_streak":
			var tip: Vector2 = p + Vector2(sin(age * 22.0) * 6.0, -40.0)
			draw_line(tip + Vector2(0, -220 * (1.0 - age * 2.4)), tip, _ink(c, life_alpha * 0.55), 5.0, true)
			draw_line(tip + Vector2(0, -160 * (1.0 - age * 2.4)), tip, _ink(Color.WHITE, life_alpha * 0.8), 1.5, true)
		"claw_rake":
			for j in range(3):
				var tear := PackedVector2Array()
				for i in range(7):
					tear.append(p + Vector2((j - 1) * 26.0 + sin(i * 8.0 + j * 2.0) * 7.0, 40.0 - i * 26.0 + age * 120.0))
				draw_polyline(tear, _ink(c, life_alpha * 0.8), 4.0 - j, true)
				draw_polyline(tear, _ink(Color.WHITE, life_alpha * 0.5), 1.2, true)
		"slash2":
			var arc := PackedVector2Array()
			for i in range(33):
				var ang: float = -2.4 + i / 32.0 * 3.7 + age * 2.2
				arc.append(p + Vector2(cos(ang) * 118.0, sin(ang) * 58.0).rotated(-0.65))
			draw_polyline(arc, _ink(c, life_alpha * 0.85), 7.0, true)
			draw_polyline(arc, _ink(Color.WHITE, life_alpha), 2.0, true)
		"sigil_pop":
			_sigil(p + Vector2(0, -95), 26.0 + age * 210.0, age * 5.0, c, life_alpha * 0.8)
		"lantern":
			var sway: float = sin(age * 6.0) * 4.0
			var lp: Vector2 = p + Vector2(sway, -110.0)
			draw_colored_polygon(PackedVector2Array([lp + Vector2(-9, -14), lp + Vector2(9, -14), lp + Vector2(12, 0), lp + Vector2(9, 14), lp + Vector2(-9, 14), lp + Vector2(-12, 0)]), _ink(Color("b5414c"), life_alpha * 0.85))
			draw_circle(lp, 5.0, _ink(Color("fff3c4"), life_alpha), true, -1, true)

func _draw_vignette(strength: float) -> void:
	var center := Vector2(640, 360)
	var seg := 40
	for i in range(seg):
		var a0: float = i * TAU / seg
		var a1: float = (i + 1) * TAU / seg
		var p0: Vector2 = center + Vector2(cos(a0) * 470.0, sin(a0) * 330.0)
		var p1: Vector2 = center + Vector2(cos(a1) * 470.0, sin(a1) * 330.0)
		var o0: Vector2 = center + (p0 - center).normalized() * 950.0
		var o1: Vector2 = center + (p1 - center).normalized() * 950.0
		var edge: float = 0.72 + 0.28 * absf(cos((a0 + a1) * 0.5))
		var col := Color(VIGNETTE_INK.r, VIGNETTE_INK.g, VIGNETTE_INK.b, clampf(strength * edge, 0.0, 1.0))
		draw_polygon(PackedVector2Array([p0, p1, o1, o0]), PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), col, col]))

# --- additive layer ----------------------------------------------------------

func draw_add(layer: CanvasItem) -> void:
	for f in flashes:
		var a: float = float(f.k) * exp(-f.age * 20.0)
		if a > 0.003:
			var c: Color = f.c
			layer.draw_rect(Rect2(-20, -20, 1320, 760), Color(c.r, c.g, c.b, a))
	for f in circles:
		var flash: float = exp(-f.age * 18.0)
		if flash > 0.01:
			layer.draw_circle(f.p, 9.0 + 28.0 * f.age, Color(1, 1, 1, flash * 0.85), true, -1, true)
			layer.draw_circle(f.p, 20.0 + 55.0 * f.age, Color(1, 1, 1, flash * 0.22), true, -1, true)
	for f in rings:
		var prog: float = clampf(f.age / 0.4, 0.0, 1.0)
		var a: float = (1.0 - prog) * 0.8
		var c: Color = f.c
		layer.draw_arc(f.p, 40.0 + prog * 70.0, 0, TAU, 44, Color(c.r, c.g, c.b, a * 0.7), 2.5, true)
		layer.draw_arc(f.p, 28.0 + prog * 82.0, 0, TAU, 40, Color(1, 1, 1, a * 0.5), 1.5, true)

# --- particles ---------------------------------------------------------------

func _gradient(colors: Array) -> Gradient:
	var g := Gradient.new()
	var packed := PackedColorArray()
	for c in colors:
		packed.append(c)
	g.colors = packed
	return g

func _scale_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.4, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	return curve

func _base_particle(pos: Vector2, one_shot: bool, additive: bool) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = one_shot
	p.explosiveness = 1.0 if one_shot else 0.0
	p.local_coords = false
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD if additive else CanvasItemMaterial.BLEND_MODE_MIX
	p.material = mat
	add_child(p)
	return p

func _expire(node: Node, seconds: float) -> void:
	get_tree().create_timer(seconds, false).timeout.connect(func() -> void:
		if node != null and is_instance_valid(node):
			node.queue_free())

func _spawn(recipe: String, pos: Vector2, c: Color, spec: Dictionary) -> void:
	match recipe:
		"burst":
			var p := _base_particle(pos + Vector2(0, -95), true, true)
			p.amount = 20
			p.lifetime = 0.55
			p.randomness = 0.4
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
			p.emission_sphere_radius = 10.0
			p.spread = 180.0
			p.initial_velocity_min = 50.0
			p.initial_velocity_max = 120.0
			p.damping_min = 50.0
			p.damping_max = 100.0
			p.gravity = Vector2.ZERO
			p.scale_amount_min = 3.0
			p.scale_amount_max = 6.0
			p.scale_amount_curve = _scale_curve()
			p.color_ramp = _gradient([Color.WHITE, c, Color(c.r, c.g, c.b, 0.0)])
			p.finished.connect(p.queue_free)
			p.emitting = true
		"embers_fire":
			for tp in [pos]:
				var p := _base_particle(tp + Vector2(0, -70), true, true)
				p.amount = 24
				p.lifetime = 0.7
				p.explosiveness = 0.7
				p.randomness = 0.4
				p.spread = 90.0
				p.direction = Vector2(0, -1)
				p.gravity = Vector2(0, -50)
				p.initial_velocity_min = 40.0
				p.initial_velocity_max = 110.0
				p.scale_amount_min = 3.0
				p.scale_amount_max = 6.0
				p.scale_amount_curve = _scale_curve()
				p.color_ramp = _gradient([Color("ffdc7c"), c, Color(c.r, c.g, c.b, 0.0)])
				p.finished.connect(p.queue_free)
				p.emitting = true
		"after_embers":
			var p := _base_particle(pos + Vector2(0, -20), true, true)
			p.amount = 30
			p.lifetime = 1.2
			p.explosiveness = 0.6
			p.spread = 70.0
			p.direction = Vector2(0, -1)
			p.gravity = Vector2(0, -50)
			p.initial_velocity_min = 30.0
			p.initial_velocity_max = 80.0
			p.scale_amount_min = 2.0
			p.scale_amount_max = 5.0
			p.color_ramp = _gradient([Color("ffe6a0"), c, Color(c.r, c.g, c.b, 0.0)])
			p.finished.connect(p.queue_free)
			p.emitting = true
		"chime":
			var p := _base_particle(pos + Vector2(0, -95), true, true)
			p.amount = 20
			p.lifetime = 0.7
			p.explosiveness = 0.6
			p.spread = 180.0
			p.gravity = Vector2(0, -50)
			p.initial_velocity_min = 30.0
			p.initial_velocity_max = 90.0
			p.scale_amount_min = 2.0
			p.scale_amount_max = 4.0
			p.scale_amount_curve = _scale_curve()
			p.color_ramp = _gradient([Color("f2ffff"), c, Color(c.r, c.g, c.b, 0.0)])
			p.finished.connect(p.queue_free)
			p.emitting = true
		"up_heal", "barrier_dust":
			var p := _base_particle(pos + Vector2(0, -60), true, true)
			p.amount = 18
			p.lifetime = 0.9
			p.explosiveness = 0.55
			p.direction = Vector2(0, -1)
			p.spread = 30.0
			p.gravity = Vector2(0, -60)
			p.initial_velocity_min = 40.0
			p.initial_velocity_max = 90.0
			p.scale_amount_min = 2.0
			p.scale_amount_max = 4.5
			p.color_ramp = _gradient([Color("eafff6"), c, Color(c.r, c.g, c.b, 0.0)])
			p.finished.connect(p.queue_free)
			p.emitting = true
		"sigil_spark":
			var p := _base_particle(pos + Vector2(0, -95), true, true)
			p.amount = 14
			p.lifetime = 0.6
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
			p.emission_sphere_radius = 22.0
			p.spread = 180.0
			p.gravity = Vector2.ZERO
			p.initial_velocity_min = 30.0
			p.initial_velocity_max = 80.0
			p.scale_amount_min = 2.0
			p.scale_amount_max = 4.0
			p.scale_amount_curve = _scale_curve()
			p.color_ramp = _gradient([Color("dce9ff"), c, Color(c.r, c.g, c.b, 0.0)])
			p.finished.connect(p.queue_free)
			p.emitting = true
		"black_flame":
			var smoke := _base_particle(pos + Vector2(0, -70), true, false)
			smoke.amount = 16
			smoke.lifetime = 0.9
			smoke.explosiveness = 0.7
			smoke.spread = 60.0
			smoke.direction = Vector2(0, -1)
			smoke.gravity = Vector2(0, -40)
			smoke.initial_velocity_min = 20.0
			smoke.initial_velocity_max = 60.0
			smoke.scale_amount_min = 4.0
			smoke.scale_amount_max = 7.0
			smoke.color_ramp = _gradient([Color("2a0e1c"), Color(0.16, 0.05, 0.11, 0.6), Color(0.1, 0.03, 0.08, 0.0)])
			smoke.finished.connect(smoke.queue_free)
			smoke.emitting = true
			var edge := _base_particle(pos + Vector2(0, -70), true, true)
			edge.amount = 14
			edge.lifetime = 0.8
			edge.explosiveness = 0.7
			edge.spread = 60.0
			edge.direction = Vector2(0, -1)
			edge.gravity = Vector2(0, -40)
			edge.initial_velocity_min = 25.0
			edge.initial_velocity_max = 70.0
			edge.scale_amount_min = 3.0
			edge.scale_amount_max = 6.0
			edge.scale_amount_curve = _scale_curve()
			edge.color_ramp = _gradient([Color("e88aa5"), c, Color(c.r, c.g, c.b, 0.0)])
			edge.finished.connect(edge.queue_free)
			edge.emitting = true
		"crow_embers":
			var p := _base_particle(pos + Vector2(0, -40), true, true)
			p.amount = 25
			p.lifetime = 0.9
			p.explosiveness = 0.6
			p.spread = 180.0
			p.gravity = Vector2(0, -30)
			p.initial_velocity_min = 30.0
			p.initial_velocity_max = 90.0
			p.scale_amount_min = 2.0
			p.scale_amount_max = 5.0
			p.scale_amount_curve = _scale_curve()
			p.color_ramp = _gradient([Color("e6d2ff"), c, Color(c.r, c.g, c.b, 0.0)])
			p.finished.connect(p.queue_free)
			p.emitting = true
		"lantern", "lantern_embers":
			if recipe == "lantern":
				accents.append({"kind": "lantern", "p": pos, "age": 0.0, "c": Color("ffd98a")})
			var p := _base_particle(pos + Vector2(0, -90), true, true)
			p.amount = 8 if recipe == "lantern" else 18
			p.lifetime = 0.9
			p.explosiveness = 0.5
			p.spread = 40.0
			p.direction = Vector2(0, -1)
			p.gravity = Vector2(0, -60)
			p.initial_velocity_min = 20.0
			p.initial_velocity_max = 60.0
			p.scale_amount_min = 2.0
			p.scale_amount_max = 4.0
			p.scale_amount_curve = _scale_curve()
			p.color_ramp = _gradient([Color("fff3c4"), c, Color(c.r, c.g, c.b, 0.0)])
			p.finished.connect(p.queue_free)
			p.emitting = true
		"claw_rake", "drop_streak", "break_slash":
			var kind := recipe if recipe != "break_slash" else "slash2"
			accents.append({"kind": kind, "p": pos, "age": 0.0, "c": c})
			var p := _base_particle(pos + Vector2(0, -80), true, true)
			p.amount = 12
			p.lifetime = 0.5
			p.spread = 180.0
			p.gravity = Vector2(0, -30)
			p.initial_velocity_min = 30.0
			p.initial_velocity_max = 90.0
			p.scale_amount_min = 2.0
			p.scale_amount_max = 4.0
			p.scale_amount_curve = _scale_curve()
			p.color_ramp = _gradient([Color.WHITE, c, Color(c.r, c.g, c.b, 0.0)])
			p.finished.connect(p.queue_free)
			p.emitting = true
		"quake_streak":
			accents.append({"kind": "drop_streak", "p": pos, "age": 0.0, "c": c})
			var p := _base_particle(pos + Vector2(0, -20), true, true)
			p.amount = 22
			p.lifetime = 0.9
			p.explosiveness = 0.7
			p.spread = 70.0
			p.direction = Vector2(0, -1)
			p.gravity = Vector2(0, 60)
			p.initial_velocity_min = 40.0
			p.initial_velocity_max = 120.0
			p.scale_amount_min = 3.0
			p.scale_amount_max = 6.0
			p.scale_amount_curve = _scale_curve()
			p.color_ramp = _gradient([CHARGE_GLOW, c, Color(c.r, c.g, c.b, 0.0)])
			p.finished.connect(p.queue_free)
			p.emitting = true
		"shield_break":
			var p := _base_particle(pos + Vector2(0, -95), true, true)
			p.amount = 25
			p.lifetime = 0.6
			p.randomness = 0.4
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
			p.emission_sphere_radius = 15.0
			p.spread = 180.0
			p.gravity = Vector2(0, 400)
			p.initial_velocity_min = 100.0
			p.initial_velocity_max = 200.0
			p.angular_velocity_min = -360.0
			p.angular_velocity_max = 360.0
			p.scale_amount_min = 3.0
			p.scale_amount_max = 6.0
			p.color_ramp = _gradient([Color(0.5, 0.8, 1.0), Color(0.3, 0.6, 1.0, 0.8), Color(0.2, 0.4, 0.8, 0.0)])
			p.finished.connect(p.queue_free)
			p.emitting = true

func _summon_circle(pos: Vector2) -> CPUParticles2D:
	var p := _base_particle(pos, false, true)
	p.amount = 25
	p.lifetime = 1.5
	p.preprocess = 0.5
	p.randomness = 0.3
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	p.emission_sphere_radius = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 20.0
	p.gravity = Vector2(0, -50)
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 60.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.scale_amount_curve = _scale_curve()
	p.color_ramp = _gradient([CHARGE_GLOW, CHARGE_COLOR, Color(CHARGE_COLOR.r, CHARGE_COLOR.g, CHARGE_COLOR.b, 0.0)])
	p.emitting = true
	return p

func _arena_ring(origin: Vector2, spec: Dictionary) -> void:
	var p := _base_particle(origin, false, true)
	p.amount = 25
	p.lifetime = 1.2
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RING
	p.emission_ring_radius = 26.0
	p.direction = Vector2(0, -1)
	p.spread = 20.0
	p.gravity = Vector2(0, -50)
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 60.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.scale_amount_curve = _scale_curve()
	var c: Color = spec.get("c", Color("ff733d"))
	p.color_ramp = _gradient([Color("ffe6a0"), c, Color(c.r, c.g, c.b, 0.0)])
	p.emitting = true
	var tw := create_tween()
	tw.tween_property(p, "emission_ring_radius", 62.0, 0.95).from(26.0)
	arena_nodes.append(p)

func _arena_mist(spec: Dictionary) -> void:
	var p := _base_particle(Vector2(640, 400), false, false)
	p.amount = 40
	p.lifetime = 2.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RING
	p.emission_ring_radius = 540.0
	p.spread = 180.0
	p.gravity = Vector2(0, -15)
	p.radial_accel_min = -110.0
	p.radial_accel_max = -110.0
	p.initial_velocity_min = 20.0
	p.initial_velocity_max = 45.0
	p.scale_amount_min = 6.0
	p.scale_amount_max = 12.0
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.2))
	p.scale_amount_curve = shrink
	var c: Color = spec.get("c", Color("b672dd"))
	p.color_ramp = _gradient([Color(c.r, c.g, c.b, 0.05), Color(c.r, c.g, c.b, 0.18), Color(c.r, c.g, c.b, 0.0)])
	p.emitting = true
	arena_nodes.append(p)

func _stop_arena() -> void:
	for p in arena_nodes:
		if p != null and is_instance_valid(p):
			p.emitting = false
			_expire(p, 2.4)
	arena_nodes.clear()

# --- helpers -----------------------------------------------------------------

func _fallback_spec(kind: String) -> Dictionary:
	return {"c": _kind_color(kind), "hi": Color.WHITE, "tele": "none", "tr": [20.0, 50.0],
		"k": 0.12, "white": true, "burst": "burst"}

func _kind_color(kind: String) -> Color:
	match kind:
		"fire": return Color("ff733d")
		"heal": return Color("79ffd2")
		"shield": return Color("8fdfff")
		"stun": return Color("ffce72")
		"boss": return Color("bb82ff")
		"dragon": return Color("7fa9ff")
		"moonbolt": return Color("97dfff")
		"raven": return Color("bda1f0")
		"raven_fire": return Color("cc5277")
		"miasma": return Color("b672dd")
		"charge": return Color("bb82ff")
	return Color("ffecad")

func _ink(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, clampf(a, 0.0, 1.0))

func _sigil(p: Vector2, radius: float, rotation_angle: float, c: Color, alpha: float) -> void:
	for ring in range(2):
		draw_arc(p, radius + ring * 9.0, rotation_angle, rotation_angle + TAU, 64, _ink(c, alpha * (0.75 - ring * 0.25)), 1.5, true)
	for i in range(8):
		var a: float = rotation_angle + i * TAU / 8.0
		var v := Vector2.from_angle(a)
		draw_line(p + v * (radius - 7.0), p + v * (radius + 7.0), _ink(c, alpha), 2.0, true)

func _ground_sigil(p: Vector2, radius: float, rotation_angle: float, c: Color, alpha: float) -> void:
	draw_set_transform(p, rotation_angle * 0.2, Vector2(1.0, 0.35))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 52, _ink(c, alpha), 1.8, true)
	draw_arc(Vector2.ZERO, radius * 0.68, 0, TAU, 44, _ink(c, alpha * 0.6), 1.2, true)
	for i in range(8):
		var a: float = i * TAU / 8.0
		var v := Vector2.from_angle(a)
		draw_line(v * (radius - 6.0), v * (radius + 6.0), _ink(c, alpha), 2.0, true)
	draw_set_transform(Vector2.ZERO)
