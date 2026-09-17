extends SceneTree
const AudioMgrScript = preload("res://scripts/audio_manager.gd")
const ACTIONS := ["entrance", "cast", "hurt", "death", "victory", "defeat"]
var failures: int = 0
var done := false
func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void:
	_run.call_deferred()
	create_timer(10.0).timeout.connect(_timeout_quit)
func _timeout_quit() -> void:
	if not done:
		done = true
		print("VOICE_TEST failures=%d timeout" % (failures + 1))
		quit(1)
func _run() -> void:
	done = true
	var mgr = AudioMgrScript.new()
	mgr.name = "AudioMgr"
	root.add_child(mgr)
	check(mgr.VOICE_UNITS.size() == 6, "VOICE_UNITS length 6")
	check(mgr.VOICE_UNITS[0] == "feiyu" and mgr.VOICE_UNITS[5] == "huangshuo", "VOICE_UNITS order matches combat ids 0-5")
	for unit in mgr.VOICE_UNITS:
		for action in ACTIONS:
			check(ResourceLoader.exists("res://assets/audio/voice/" + unit + "_" + action + ".ogg"), "voice file exists: " + unit + "_" + action)
	check(mgr._voice is AudioStreamPlayer and mgr._voice.bus == "SFX", "voice routed to SFX bus")
	check(absf(mgr._voice.volume_db - (-2.0)) < 0.001, "voice volume -2 dB")
	mgr.play_unit_voice(-1, "cast")
	mgr.play_unit_voice(6, "cast")
	mgr.play_unit_voice(999, "entrance")
	check(mgr._voice.stream == null, "invalid unit index does not crash nor assign")
	mgr.play_voice("no_such_voice_404")
	check(mgr._voice.stream == null, "missing voice file skipped silently")
	mgr.play_unit_voice(2, "cast")
	check(mgr._voice.stream != null and mgr._voice.stream.resource_path.ends_with("chengling_cast.ogg"), "play_unit_voice maps unit index to file")
	var first: AudioStream = mgr._voice.stream
	mgr.play_unit_voice(5, "death")
	check(mgr._voice.playing, "second voice call replaces single instance")
	check(mgr._voice.stream != first, "previous stream replaced on new voice")
	mgr._voice.stop()
	mgr._voice.stream = null
	mgr.queue_free()
	print("VOICE_TEST failures=%d" % failures)
	quit(0 if failures == 0 else 1)
