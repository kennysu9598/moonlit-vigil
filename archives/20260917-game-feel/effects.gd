class_name MoonEffects
extends Node2D

signal environment(kind: String, strength: float)
signal impact
signal shake(amount: float)
var font: Font
var modeled_primary:=false
var visual_approved:=false
var _effects: Array[Dictionary] = []
var _floats: Array[Dictionary] = []
var _epoch: int = 0

func _ready() -> void:
	z_index = 80
	set_process(false)

func reset() -> void:
	_epoch += 1
	_effects.clear()
	environment.emit("", 0.0)
	_floats.clear()
	set_process(false)
	queue_redraw()

func play(kind: String, origin: Vector2, targets: Array[Vector2], power: float = 1.0) -> void:
	var duration: float = 2.8 if power >= 2.0 else 0.86
	var peak: float = 1.55 if power >= 2.0 else 0.4
	var token: int = _epoch
	var fx: Dictionary = {"kind": kind, "origin": origin, "targets": targets.duplicate(), "power": power, "age": 0.0, "duration": duration, "peak": peak,"modeled":modeled_primary}
	_effects.append(fx)
	set_process(true)
	await get_tree().create_timer(peak).timeout
	if token != _epoch:
		return
	impact.emit()
	if kind != "heal" and kind != "shield":
		shake.emit(9.0 if power >= 2.0 else 4.0)
	await get_tree().create_timer(duration - peak).timeout
	if token == _epoch:
		_effects.erase(fx)
		if _effects.is_empty(): environment.emit("", 0.0)
		queue_redraw()
		set_process(not _effects.is_empty() or not _floats.is_empty())

func floating(pos: Vector2, text: String, color: Color) -> void:
	_floats.append({"pos": pos, "text": text, "color": color, "age": 0.0})
	set_process(true)

func _process(delta: float) -> void:
	for fx in _effects:
		fx.age += delta
		if fx.power >= 2.0:
			var strength: float = minf(clampf(fx.age / 0.7, 0, 1), clampf((fx.duration - fx.age) / 0.85, 0, 1))
			environment.emit(fx.kind, strength)
	for f in _floats:
		f.age += delta
	_floats = _floats.filter(func(f: Dictionary) -> bool: return f.age < 1.15)
	queue_redraw()
	if _effects.is_empty() and _floats.is_empty():
		set_process(false)

func _ink(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, clampf(a, 0.0, 1.0))

func _color(kind: String) -> Color:
	match kind:
		"fire": return Color("ff733d")
		"heal": return Color("79ffd2")
		"shield": return Color("8fdfff")
		"stun": return Color("ffce72")
		"boss": return Color("bb82ff")
		"dragon":return Color("7fa9ff")
		"moonbolt":return Color("97dfff")
		"raven":return Color("bda1f0")
		"raven_fire":return Color("cc5277")
		"spirit":return Color("64eec3")
		"miasma":return Color("b672dd")
		"quake","charge":return Color("b68aef")
	return Color("ffecad")

func _draw() -> void:
	for fx in _effects:
		if visual_approved:_draw_effect(fx)
	var face: Font = font if font != null else ThemeDB.fallback_font
	for f in _floats:
		var age: float = f.age
		var p: Vector2 = f.pos + Vector2(-35, -110 - age * 72)
		var a: float = minf(1.0, (1.15 - age) * 3.0)
		draw_string_outline(face, p, f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 33, 6, _ink(Color("182032"), a))
		draw_string(face, p, f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 33, _ink(f.color, a))

func _sigil(p: Vector2, radius: float, rotation_angle: float, c: Color, alpha: float) -> void:
	for ring in range(2):
		draw_arc(p, radius + ring * 9, rotation_angle, rotation_angle + TAU, 64, _ink(c, alpha * (0.75 - ring * 0.25)), 1.5, true)
	for i in range(8):
		var a: float = rotation_angle + i * TAU / 8
		var v: Vector2 = Vector2.from_angle(a)
		draw_line(p + v * (radius - 7), p + v * (radius + 7), _ink(c, alpha), 2, true)
		var tip: Vector2 = p + v * (radius - 14)
		draw_line(tip, p + Vector2.from_angle(a + 2.0 * PI / 3.0) * (radius - 14), _ink(c, alpha * 0.25), 1, true)

func _draw_effect(fx: Dictionary) -> void:
	if fx.power >= 2.0:
		_draw_ultimate(fx)
		return
	var t: float = fx.age
	var peak: float = fx.peak
	var after: float = maxf(0, t - peak)
	var fade: float = clampf((fx.duration - t) / (fx.duration - peak), 0, 1)
	var charge: float = clampf(t / peak, 0, 1)
	var c: Color = _color(fx.kind)
	var power: float = fx.power
	var source: Vector2 = fx.origin + Vector2(0, -100)
	var flash: float = exp(-after * 20.0) if t >= peak else 0.0
	if power >= 2:
		draw_rect(Rect2(0, 0, 1280, 720), _ink(Color("080b20"), sin(clampf(t / fx.duration, 0, 1) * PI) * 0.55))
		draw_rect(Rect2(0, 0, 1280, 720), _ink(c, flash * 0.23))
	if t < peak:
		_sigil(source, 26 + charge * 36, t * 2, c, sin(charge * PI) * 0.75)
		for i in range(14):
			var angle: float = i * TAU / 14 + t * 3
			var p: Vector2 = source + Vector2.from_angle(angle) * (110 * (1 - charge) + 12)
			draw_circle(p, 2 + charge * 2, _ink(c, charge), true, -1, true)
	for target in fx.targets:
		var center: Vector2 = target + Vector2(0, -100)
		if t < peak:
			var head: Vector2 = source.lerp(center, charge * charge)
			var tail: Vector2 = source.lerp(center, maxf(0, charge * charge - 0.22))
			draw_line(tail, head, _ink(c, charge * 0.18), 16, true)
			draw_line(tail, head, _ink(c, charge * 0.7), 3, true)
		else:
			_draw_hit(fx.kind, center, after, fade, flash, c, power)

func _draw_hit(kind: String, p: Vector2, t: float, fade: float, flash: float, c: Color, power: float) -> void:
	var spread: float = 1.0 + (power - 1.0) * 0.35
	draw_circle(p, (30 + 70 * t) * spread, _ink(c, flash * 0.18), true, -1, true)
	draw_circle(p, (9 + 28 * t) * spread, _ink(Color.WHITE, flash * 0.85), true, -1, true)
	match kind:
		"slash":
			for j in range(3):
				var points := PackedVector2Array()
				for i in range(33):
					var angle: float = -2.4 + i / 32.0 * 3.7 + t * 1.6
					points.append(p + Vector2(cos(angle) * (105 + j * 12), sin(angle) * (54 + j * 8)).rotated(-0.65) * spread)
				draw_polyline(points, _ink(c if j != 1 else Color.WHITE, fade * (0.8 - j * 0.15)), (8 - j * 2) * fade + 0.5, true)
		"fire":
			for i in range(13):
				var x: float = sin(i * 2.3) * 96 * spread
				var fall: float = fmod(t * 520 + i * 39, 220)
				var tip: Vector2 = p + Vector2(x, fall - 145)
				draw_line(tip - Vector2(28, 85), tip, _ink(c, fade * 0.24), 15, true)
				draw_line(tip - Vector2(20, 60), tip, _ink(Color("ffdc7c"), fade), 4, true)
				draw_circle(tip, 4, _ink(Color.WHITE, fade), true, -1, true)
		"heal":
			for i in range(19):
				var a: float = i * 2.4 + t * 2
				var petal: Vector2 = p + Vector2(sin(a) * (45 + i * 3), 110 - fmod(i * 17 + t * 170, 240))
				var d: Vector2 = Vector2.from_angle(a) * 11
				draw_colored_polygon(PackedVector2Array([petal - d, petal + d.orthogonal() * 0.4, petal + d, petal - d.orthogonal() * 0.4]), _ink(c, fade * 0.9))
			_sigil(p + Vector2(0, 65), 68 * spread, -t, c, fade * 0.7)
		"shield":
			var hex := PackedVector2Array()
			for i in range(7):
				hex.append(p + Vector2.from_angle(i * TAU / 6 - PI / 2) * 105 * spread)
			draw_colored_polygon(hex.slice(0, 6), _ink(c, fade * 0.1))
			draw_polyline(hex, _ink(c, fade), 3, true)
			_sigil(p, 88 * spread, t * 0.5, Color("ffe0a1"), fade * 0.9)
		"stun":
			for i in range(5):
				var a: float = i * TAU / 5 + t
				var q: Vector2 = p + Vector2(cos(a) * 86, sin(a) * 42 - 55)
				draw_set_transform(q, sin(a) * 0.3)
				draw_rect(Rect2(-13, -28, 26, 56), _ink(Color("fff0c0"), fade))
				for j in range(4):
					draw_line(Vector2(-7, -19 + j * 11), Vector2(7, -15 + j * 10), _ink(Color("b5414c"), fade), 2, true)
				draw_set_transform(Vector2.ZERO)
		"boss":
			for j in range(4):
				var bolt := PackedVector2Array()
				for i in range(10):
					bolt.append(p + Vector2(sin(i * 11.7 + j * 2.4 + floor(t * 18)) * 42 * (1 - i / 12.0), -350 + i * 39))
				draw_polyline(bolt, _ink(c, fade * 0.3), 18, true)
				draw_polyline(bolt, _ink(c.lightened(0.5), fade), 3, true)
	for i in range(20):
		var a: float = i * 2.399
		var velocity: Vector2 = Vector2.from_angle(a)
		var q: Vector2 = p + velocity * (22 + t * (130 + (i % 4) * 50)) * spread
		var tail: Vector2 = q - velocity * (8 + (i % 3) * 6)
		draw_line(tail, q, _ink(c, fade * fade * 0.8), 2 if i % 2 else 3, true)

# Four phases: silhouette rises (0-.95), battlefield release (.95-1.55),
# single logical impact (1.55), grounded wake and atmosphere recovery (1.55-2.8).
func _glow_path(points: PackedVector2Array, c: Color, alpha: float, width: float) -> void:
	if alpha <= 0.001 or points.size() < 2: return
	draw_polyline(points, _ink(c, alpha * 0.07), width * 5, true)
	draw_polyline(points, _ink(c, alpha * 0.22), width * 2.2, true)
	draw_polyline(points, _ink(c.lightened(0.35), alpha), width, true)

func _feather(base: Vector2, tip: Vector2, width: float, c: Color, alpha: float) -> void:
	var v: Vector2 = tip - base
	var side: Vector2 = v.normalized().orthogonal() * width
	var edge := PackedVector2Array([base, base + v * 0.34 + side, tip, base + v * 0.58 - side * 0.5])
	draw_colored_polygon(edge, _ink(c, alpha * 0.25))
	_glow_path(PackedVector2Array([base, base + v * 0.38 + side * 0.35, tip]), c, alpha, 2.2)

func _ellipse(center: Vector2, radius: Vector2, c: Color, alpha: float, width: float, rotation_angle: float = 0.0) -> void:
	var points := PackedVector2Array()
	for i in range(81):
		var a: float = i * TAU / 80
		points.append(center + (Vector2(cos(a), sin(a)) * radius).rotated(rotation_angle))
	_glow_path(points, c, alpha, width)

func _moon(center: Vector2, radius: float, c: Color, alpha: float, phase: float) -> void:
	var outer := PackedVector2Array()
	var shape := PackedVector2Array()
	for i in range(49):
		var a: float = -1.4 + i * 2.8 / 48
		var point: Vector2 = center + Vector2(-cos(a), sin(a)) * radius
		shape.append(point)
		outer.append(point)
	for i in range(48, -1, -1):
		var a: float = -1.4 + i * 2.8 / 48
		shape.append(center + Vector2(-cos(a) * (0.45 + phase * 0.12), sin(a)) * radius)
	draw_colored_polygon(shape, _ink(c, alpha * 0.18))
	_glow_path(outer, c, alpha, 3)

func _draw_ultimate(fx: Dictionary) -> void:
	var t: float = fx.age
	var p: Vector2 = Vector2.ZERO
	for target in fx.targets: p += target
	p = p / maxf(1, fx.targets.size()) if not fx.targets.is_empty() else fx.origin
	var c: Color = _color(fx.kind)
	var fade: float = clampf((2.8 - t) / 1.0, 0, 1)
	var build: float = smoothstep(0.0, 1.1, t)
	var after: float = maxf(0.0, t - 1.55)
	var pulse: float = exp(-after * 25.0) if t >= 1.55 else 0.0
	var center: Vector2 = p + Vector2(0, -160)
	if bool(fx.get("modeled",false)):
		# The real 3D asset owns the main silhouette; 2D only supplies trails and landing.
		for i in range(28):
			var angle:=i*2.399+t*.7
			var q:=center+Vector2(cos(angle)*240,sin(angle)*105)*build
			var tail:=q+Vector2(-30,22) if fx.kind in ["fire","raven_fire"] else q+Vector2(-14,-7)
			draw_line(q,tail,_ink(c,fade*build*.45),2,true)
		if t>=1.55:
			_ground_wake(p,after,fade,c,fx.kind)
			_ellipse(p,Vector2(190+after*190,45+after*38),c,pulse,8)
		return
	# No opaque screen wash: retain character silhouettes through local linework.
	match str(fx.kind):
		"fire":
			var travel: float = smoothstep(0.55, 1.6, t)
			var bird: Vector2 = (fx.origin + Vector2(0,-135)).lerp(center + Vector2(0,-30), travel)
			bird += Vector2(100 * after, -45 * after)
			var wing_span: float = (90 + 190 * build) * (1 + after * 0.12)
			var life: float = fade * clampf((2.35 - t) * 2, 0, 1)
			for side in [-1, 1]:
				var curve := PackedVector2Array()
				for i in range(11):
					var u: float = i / 10.0
					var root_point: Vector2 = bird + Vector2(side * u * wing_span, -sin(u * PI * 0.75) * 110 * build)
					curve.append(root_point)
					var tip: Vector2 = root_point + Vector2(side * (40 + u * 80), 65 + u * 85) * (0.5 + build * 0.5)
					_feather(root_point, tip, 16 + u * 8, c.lerp(Color("ffde85"), u), life * build)
				_glow_path(curve, Color("ffe6a0"), life, 5)
			_feather(bird + Vector2(0,35), bird + Vector2(0,-95), 28, Color("fff4bc"), life)
			for i in range(9):
				var tail: Vector2 = bird + Vector2(sin(i * 1.8) * 90, 160 + i * 10 + after * 80)
				_feather(bird + Vector2((i-4)*8,15), tail, 10, c, life * 0.75)
		"slash":
			_moon(center + Vector2(0,-35), 135 * build, Color("e77868"), fade * build * 0.65, 0.0)
			for j in range(3):
				var onset: float = 1.03 + j * 0.26
				var local: float = t - onset
				if local < 0 or local > 0.34: continue
				var a: float = pow(1 - local / 0.34, 1.7)
				var direction: float = [-0.7, 0.65, -0.08][j]
				var blade := PackedVector2Array()
				for i in range(45):
					var u: float = i / 44.0
					blade.append(center + Vector2((u - 0.5) * (620 + j * 45), sin(u * PI) * -70).rotated(direction))
				_glow_path(blade, Color("ff625d"), a, 16 if j == 2 else 10)
				_glow_path(blade, Color("fff7de"), a, 4 if j == 2 else 2)
		"shield", "heal":
			var moon_color := Color("96efff") if fx.kind == "shield" else Color("83ffd7")
			_moon(center + Vector2(0,-115), 100 * build, moon_color, fade * build, 1)
			_ellipse(p + Vector2(0,-4), Vector2(275,70) * maxf(0.1, build), moon_color, fade * 0.7, 2)
			for i in range(45):
				var star: Vector2 = p + Vector2(sin(i * 13.7) * 260, -fmod(i * 31.0 + t * 24, 310))
				var a: float = fade * build * (0.45 + 0.3 * sin(i + t * 3))
				draw_line(star-Vector2(3,0), star+Vector2(3,0), _ink(moon_color,a), 1.5, true)
				draw_line(star-Vector2(0,5), star+Vector2(0,5), _ink(moon_color,a), 1.5, true)
			for target in fx.targets:
				var shell := PackedVector2Array()
				for i in range(41):
					var angle: float = PI + i * PI / 40
					shell.append(target + Vector2(cos(angle)*100,sin(angle)*240)*build)
				_glow_path(shell, moon_color, fade * build, 3)
				if fx.kind == "heal":
					for j in range(7):
						var q: Vector2 = target + Vector2(sin(j*2.2+t)*65,-fmod(j*31+t*100,200))
						_feather(q, q+Vector2(12,-22), 5, moon_color, fade)
		"boss":
			var fall: float = smoothstep(0.75, 1.55, t)
			var orb: Vector2 = center + Vector2(0, -230 * (1 - fall))
			var orb_alpha: float = build * clampf(1 - after * 3, 0, 1)
			draw_circle(orb, 104 * build, _ink(Color("110c26"),orb_alpha * 0.9),true,-1,true)
			_ellipse(orb, Vector2(112,112)*maxf(0.01,build), c, orb_alpha, 5)
			_ellipse(orb, Vector2(180,35)*maxf(0.01,build), c, orb_alpha*0.6, 2, -0.35)
			for j in range(7):
				var bolt := PackedVector2Array()
				for i in range(8):
					bolt.append(orb+Vector2(sin(i*8.7+j*2+floor(t*14))*35 + (j-3)*35, -150+i*40))
				_glow_path(bolt,c,fade*build*(0.4+pulse*0.6),2.5)
		"stun":
			_sigil(center, 110 * build, -t * 0.5, c, fade * build)
			for j in range(7):
				var q: Vector2 = center + Vector2.from_angle(j*TAU/7+t*0.4)*150*build
				_feather(q+Vector2(0,38),q-Vector2(0,38),20,c,fade*build)
	if t >= 1.55:
		_ground_wake(p, after, fade, c, fx.kind)
		# Local flash lasts ~100ms and does not cover the full field.
		_ellipse(p, Vector2(190+after*190,45+after*38), c, pulse, 8)

func _ground_wake(p: Vector2, t: float, fade: float, c: Color, kind: String) -> void:
	var gentle: bool = kind == "shield" or kind == "heal"
	for j in range(3):
		var r: float = maxf(0.0, t - j * 0.13)
		if r <= 0: continue
		_ellipse(p, Vector2(90 + r * 240, 22 + r * 58), c, fade * (0.55 - j * 0.12), 2 if gentle else 3)
	if not gentle:
		for j in range(9):
			var crack := PackedVector2Array([p])
			var direction: Vector2 = Vector2.from_angle(j * TAU / 9)
			for i in range(1,6):
				var q: Vector2 = direction * i * 42 * minf(1,t*5)
				q += direction.orthogonal() * sin(i*8+j)*17
				crack.append(p + Vector2(q.x,q.y*0.25))
			_glow_path(crack, c, fade * 0.7, 1.6)
	for i in range(35):
		var q: Vector2 = p + Vector2(sin(i*12.3)*(45+t*170), -t*(50+i%6*20)-absf(sin(i*4))*25)
		if kind == "fire":
			_feather(q,q+Vector2(7,-22),3,c,fade*0.65)
		else:
			draw_line(q,q+Vector2(2,-6),_ink(c,fade*0.6),2,true)
