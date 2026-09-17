extends SceneTree
const VfxScript = preload("res://scripts/skill_vfx.gd")
const ActorScript = preload("res://scripts/actor.gd")
var failures: int = 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)

func _init() -> void: call_deferred("run")

func run() -> void:
	var vfx = VfxScript.new()
	root.add_child(vfx)
	check(vfx.add_layer != null, "additive layer exists")
	var points: Array[Vector2] = [Vector2(900, 430), Vector2(1100, 540)]
	# 1) All 18 skill constructs run, fire impact and expire without crashing.
	for unit in range(6):
		for slot in range(3):
			vfx.play_skill(unit, slot, "fire", Vector2(300, 430), points, slot)
			check(not vfx.casts.is_empty(), "cast registered u%ds%d" % [unit, slot])
			vfx._process(1.0 / 60.0)
			vfx.on_impact(slot == 2, points)
			vfx._process(0.05)
	vfx._process(2.6)
	check(vfx.casts.is_empty(), "casts expire after impact")
	check(vfx.flashes.is_empty() and vfx.circles.is_empty() and vfx.accents.is_empty(), "impact accents expire")
	check(vfx.arena_nodes.is_empty(), "arena particles stopped at impact")
	print("VFX_CONSTRUCT unit=0..5 slot=0..2 casts=18 impact+expiry ok")
	# 2) Ultimate impact raises the vignette; reset clears it.
	vfx.play_skill(0, 2, "fire", Vector2(300, 430), points, 2)
	vfx.on_impact(true, points)
	check(vfx.vig_pulse > 0.3, "ultimate vignette spike")
	vfx.reset()
	check(vfx.vig_pulse <= 0.005 and vfx.vig_base <= 0.005 and vfx.casts.is_empty(), "reset clears state")
	# 3) Missing-parameter fallback: unknown unit/slot and empty target arrays.
	vfx.play_skill(9, 9, "unknown_kind", Vector2.ZERO, [], 7)
	vfx.on_impact(false, [])
	vfx._process(0.05)
	check(not vfx.casts.is_empty(), "fallback spec registers cast")
	vfx.reset()
	vfx.update_shields([])
	check(vfx.shields.is_empty(), "empty shield list accepted")
	print("VFX_FALLBACK unknown spec/empty targets ok")
	# 4) Frozen timing tables.
	check(absf(VfxScript.windup_for(0) - 0.06) < 0.001 and absf(VfxScript.windup_for(1) - 0.09) < 0.001 and absf(VfxScript.windup_for(2) - 0.14) < 0.001, "tiered wind-up 0.06/0.09/0.14")
	check(absf(VfxScript.peak_for(0) - 0.18) < 0.001 and absf(VfxScript.peak_for(1) - 0.40) < 0.001 and absf(VfxScript.peak_for(2) - 1.55) < 0.001, "tier peaks 0.18/0.40/1.55")
	check(absf(VfxScript.freeze_for(0, 2) - 0.10) < 0.001 and absf(VfxScript.freeze_for(3, 2) - 0.08) < 0.001 and absf(VfxScript.freeze_for(5, 2) - 0.10) < 0.001 and VfxScript.freeze_for(0, 0) == 0.0, "freeze table")
	print("VFX_TIMING windup/peak/freeze tables frozen")
	# 5) Boss charge warning array show/hide.
	vfx.begin_boss_charge(Vector2(830, 560))
	check(vfx.charge_active and vfx.charge_node != null and is_instance_valid(vfx.charge_node), "charge array spawns")
	vfx._process(2.5)
	check(vfx.vig_base > 0.4, "charge vignette ramps to 0.45")
	vfx.release_boss_charge(Vector2(830, 560))
	check(not vfx.charge_active, "charge array released")
	vfx._process(1.0)
	check(vfx.vig_base < 0.1, "vignette decays after release")
	vfx.reset()
	print("VFX_BOSS_CHARGE array+vignette show/release ok")
	# 6) Shield display logic on the actor: gain -> fill, drop -> broken signal.
	var actor = ActorScript.new()
	root.add_child(actor)
	var data := {"id": 1, "name": "澄铃", "team": 0, "hp": 100, "max_hp": 100, "atk": 18, "speed": 60, "shield": 0, "stun": 0, "burn": 0, "alive": true, "charging": false, "enraged": false, "turns": 0}
	actor.setup(data.duplicate(true), null, null, 0)
	var gained := [false]
	var broken := [false]
	actor.shield_gained.connect(func(_p: Vector2) -> void: gained[0] = true)
	actor.shield_broken.connect(func(_p: Vector2) -> void: broken[0] = true)
	var shielded := data.duplicate(true)
	shielded["shield"] = 40
	actor.sync(shielded)
	check(gained[0], "shield gain signalled")
	for frame in range(6):
		await process_frame
	check(actor.shield_fill > 0.05, "shield cell fills toward value")
	var drained := shielded.duplicate(true)
	drained["shield"] = 0
	actor.sync(drained)
	check(broken[0], "shield break signalled")
	check(actor.sprite.material == null, "outline glow hidden at zero shield")
	var dead := drained.duplicate(true)
	dead["alive"] = false
	dead["hp"] = 0
	actor.sync(dead)
	await create_timer(0.7).timeout
	check(actor.sprite.modulate.a < 0.6, "fallen pose fades to persistent alpha")
	check(actor.sprite.modulate.a > 0.2, "fallen pose stays visible (no full fade-out)")
	print("VFX_SHIELD gain/fill/break/outline/fallen ok")
	actor.queue_free()
	vfx.queue_free()
	print("VFX_TEST failures=%d constructs=18 fallback=on shield=on charge=on" % failures)
	quit(0 if failures == 0 else 1)
