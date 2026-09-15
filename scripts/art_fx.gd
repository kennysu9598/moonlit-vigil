extends Node2D
# Candidate painted mesh animation. It is not a 3D model and does not emit hits.
const GRID := 40
const SIZE := 420.0
const PHOENIX_SIZE := 400.0
const EYES := [Vector2(588, 326), Vector2(571, 327), Vector2(586, 308), Vector2(568, 308)]
const FLAP_ORDER := [0, 3, 1, 2]
var _frames: Array[Texture2D] = []
var _frame: int = 0
const DURATION := 2.8
const IMPACT := 1.55
const CHAIN := [Vector2(0.86, 0.26), Vector2(0.66, 0.27), Vector2(0.69, 0.44), Vector2(0.72, 0.58), Vector2(0.53, 0.59), Vector2(0.37, 0.40), Vector2(0.17, 0.47), Vector2(0.13, 0.66), Vector2(0.31, 0.76), Vector2(0.45, 0.88), Vector2(0.64, 0.94)]
var active: bool = false
var debug_freeze_travel: bool = false
var _polygon: Polygon2D
var _base := PackedVector2Array()
var _weights: Array[PackedFloat32Array] = []
var _visible_indices: Array[int] = []
var _time: float = 0.0
var _unit: int = -1
var _origin := Vector2.ZERO
var _destination := Vector2.ZERO

func _ready() -> void:
	z_index = 85
	set_process(false)

func start(unit_id: int, skill_index: int, origin: Vector2, targets: Array[Vector2], ultimate: bool) -> void:
	reset()
	if not ultimate or skill_index != 2 or unit_id not in [0, 2]: return
	var path := "res://assets/vfx_art/%s-v1.png" % ("phoenix-flap" if unit_id == 0 else "dragon")
	var texture: Texture2D
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		var source_image := Image.load_from_file(path)
		if source_image != null: texture = ImageTexture.create_from_image(source_image)
	if texture == null: return
	if unit_id == 0:
		var sheet: Image = texture.get_image()
		if sheet.get_size() != Vector2i(1254, 1254): return
		for frame in range(4):
			# Independent in-memory crops make neighboring atlas cells unsampleable.
			var region := Rect2i((frame % 2) * 627, (frame / 2) * 627, 627, 627)
			_frames.append(ImageTexture.create_from_image(sheet.get_region(region)))
		texture = _frames[0]
	_unit = unit_id
	_origin = Vector2(origin.x + 60.0, 345.0)
	_destination = origin
	if not targets.is_empty():
		_destination = Vector2.ZERO
		for target in targets: _destination += target
		_destination /= targets.size()
	var head := Vector2(0.92, 0.52) if unit_id == 0 else Vector2(0.86, 0.26)
	_destination += Vector2(0, -90) - (head - Vector2(0.5, 0.5)) * (PHOENIX_SIZE if unit_id == 0 else SIZE)
	_polygon = Polygon2D.new()
	_polygon.texture = texture
	_polygon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var source_image: Image = texture.get_image()
	var uv := PackedVector2Array()
	var triangles: Array[PackedInt32Array] = []
	for y in range(GRID + 1):
		for x in range(GRID + 1):
			var point := Vector2(float(x) / GRID, float(y) / GRID)
			_base.append(point)
			var pixel := Vector2i(point * Vector2(source_image.get_size() - Vector2i.ONE))
			if source_image.get_pixelv(pixel).a > 0.01: _visible_indices.append(_base.size() - 1)
			uv.append(point * texture.get_size())
			_weights.append(_dragon_weights(point) if unit_id == 2 else PackedFloat32Array())
	for y in range(GRID):
		for x in range(GRID):
			var a := y * (GRID + 1) + x
			triangles.append(PackedInt32Array([a, a + 1, a + GRID + 2]))
			triangles.append(PackedInt32Array([a, a + GRID + 2, a + GRID + 1]))
	_polygon.polygon = _base
	_polygon.uv = uv
	_polygon.polygons = triangles
	add_child(_polygon)
	active = true
	set_process(true)
	_render_pose()

func _dragon_weights(point: Vector2) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	var total := 0.0
	for joint in CHAIN:
		var weight := exp(-point.distance_squared_to(joint) / 0.028)
		result.append(weight)
		total += weight
	for i in range(result.size()): result[i] /= maxf(total, 0.000001)
	return result

func _frame_at(time: float) -> int:
	if time >= 0.92: return 2 # Tuck for the final strike, never cross-fade heads.
	return FLAP_ORDER[int(floor(time / 0.14)) % 4]

func _phoenix(point: Vector2, time: float) -> Vector2:
	# Real drawn wing poses provide the stroke. Only trailing feathers get tiny motion.
	var tail := smoothstep(0.68, 0.88, point.y) * (1.0 - smoothstep(0.48, 0.68, point.x))
	var result := point + Vector2(0.012 * sin(time * 7.0 - point.y * 4.0), 0.005 * sin(time * 6.0 - point.x * 3.0)) * tail
	return result + (EYES[0] - EYES[_frame_at(time)]) / 627.0

func _dragon_joints(time: float) -> Array[Transform2D]:
	var result: Array[Transform2D] = []
	for i in range(CHAIN.size()):
		var progress := float(i) / (CHAIN.size() - 1)
		var phase := time * 6.0 - progress * (5.0 + smoothstep(0.6, 1.45, time) * 1.3)
		var amplitude := 0.006 + 0.0324 * progress
		var displacement := Vector2(sin(phase) * amplitude * 0.45, cos(phase) * amplitude)
		var angle := sin(phase - 0.6) * 0.065 * progress
		var joint: Vector2 = CHAIN[i]
		result.append(Transform2D(angle, joint + displacement - joint.rotated(angle)))
	return result

func _dragon(point: Vector2, weights: PackedFloat32Array, poses: Array[Transform2D]) -> Vector2:
	var result := Vector2.ZERO
	for i in range(poses.size()): result += (poses[i] * point) * weights[i]
	# Head, eyes and jaw use one rigid transform; whiskers below/behind follow neck.
	var head := smoothstep(0.71, 0.84, point.x) * (1.0 - smoothstep(0.36, 0.46, point.y))
	result = result.lerp(poses[0] * point, head)
	var claws := [Vector2(0.91, 0.48), Vector2(0.62, 0.66), Vector2(0.20, 0.55)]
	var bones := [3, 4, 6]
	for i in range(claws.size()):
		var rigid := 1.0 - smoothstep(0.065, 0.12, point.distance_to(claws[i]))
		result = result.lerp(poses[bones[i]] * point, rigid)
	return result

func _render_pose() -> void:
	if not active: return
	if _unit == 0:
		_frame = _frame_at(_time)
		_polygon.texture = _frames[_frame]
	var vertices := PackedVector2Array()
	var joints: Array[Transform2D] = []
	if _unit == 2: joints = _dragon_joints(_time)
	for i in range(_base.size()):
		var point: Vector2 = _base[i]
		var moved := _phoenix(point, _time) if _unit == 0 else _dragon(point, _weights[i], joints)
		vertices.append((moved - Vector2(0.5, 0.5)) * (PHOENIX_SIZE if _unit == 0 else SIZE))
	# Fit the visible anatomy, not only its center, inside the battlefield.
	var bounds := Rect2(vertices[_visible_indices[0]], Vector2.ZERO)
	for index in _visible_indices: bounds = bounds.expand(vertices[index])
	if _unit == 0:
		# One conservative union across all eye-aligned cells: no per-frame autofit.
		bounds = Rect2(-205, -204, 425, 420)
	var fit := 1.0 if _unit == 0 else minf(1.0, 420.0 / maxf(bounds.size.y, 1.0))
	if fit < 1.0:
		for i in range(vertices.size()): vertices[i] *= fit
		bounds.position *= fit
		bounds.size *= fit
	_polygon.polygon = vertices
	var travel := smoothstep(0.6, IMPACT, _time)
	_polygon.position = _origin if debug_freeze_travel else _origin.lerp(_destination, travel)
	if not debug_freeze_travel:
		_polygon.position.y -= sin(travel * PI) * 14.0
		_polygon.position.x = clampf(_polygon.position.x, 85.0 - bounds.position.x, 1195.0 - bounds.end.x)
		_polygon.position.y = clampf(_polygon.position.y, 150.0 - bounds.position.y, 570.0 - bounds.end.y)
	# Normal color modulation only: never additive, never white flash.
	_polygon.modulate.a = smoothstep(0.0, 0.12, _time) * (1.0 - smoothstep(IMPACT, 1.94, _time))

func _process(delta: float) -> void:
	if not active: return
	_time += delta
	if _time >= DURATION:
		reset()
		return
	_render_pose()

func debug_seek(time: float, freeze_travel: bool = true) -> void:
	debug_freeze_travel = freeze_travel
	_time = clampf(time, 0.0, DURATION)
	set_process(false)
	_render_pose()

func debug_anchor_pose(point: Vector2, time: float) -> Vector2:
	if _unit == 0: return _phoenix(point, time) * PHOENIX_SIZE
	return _dragon(point, _dragon_weights(point), _dragon_joints(time)) * SIZE

func reset() -> void:
	active = false
	set_process(false)
	_time = 0.0
	debug_freeze_travel = false
	if is_instance_valid(_polygon):
		remove_child(_polygon)
		_polygon.queue_free()
	_polygon = null
	_base.clear()
	_weights.clear()
	_visible_indices.clear()
	_frames.clear()
	_frame = 0
