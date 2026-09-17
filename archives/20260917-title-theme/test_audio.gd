extends SceneTree
const AudioMgrScript = preload("res://scripts/audio_manager.gd")
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
		print("AUDIO_TEST failures=%d timeout" % (failures + 1))
		quit(1)
func _run() -> void:
	done = true
	var mgr = AudioMgrScript.new()
	mgr.name = "AudioMgr"
	root.add_child(mgr)
	check(mgr._pool.size() == 8, "sfx pool size 8")
	check(mgr._music.size() == 2, "music channels 2")
	for p in mgr._pool:check(p is AudioStreamPlayer and p.bus == "SFX", "pool routed to SFX")
	for p in mgr._music:check(p is AudioStreamPlayer and p.bus == "Music", "music routed to Music")
	check(AudioServer.get_bus_index("Music") != -1 and AudioServer.get_bus_index("SFX") != -1, "buses exist")
	var slot: int = mgr._next
	mgr.play_sfx("no_such_sound_404")
	check(mgr._next == slot and mgr._pool[slot].stream == null, "missing sfx skipped silently")
	if ResourceLoader.exists("res://assets/audio/ui_select.ogg"):
		mgr.play_sfx("ui_select")
		check(mgr._pool[slot].stream != null, "existing sfx assigned to pool slot")
		check(absf(mgr._pool[slot].pitch_scale - 1.0) <= 0.0601, "pitch jitter bounded")
	var c0: int = mgr.music_stream_assigns
	mgr.play_music("battle")
	check(mgr.music_stream_assigns == c0 + 1, "battle music stream assigned")
	mgr.play_music("battle")
	check(mgr.music_stream_assigns == c0 + 1, "same key does not restart")
	mgr.play_music("no_such_key")
	check(mgr.music_stream_assigns == c0 + 1, "unknown key ignored")
	for key in mgr.MUSIC:
		if not ResourceLoader.exists(mgr.MUSIC[key]):
			mgr.play_music(key)
			check(mgr.music_stream_assigns == c0 + 1, "missing music file skipped: " + str(key))
	mgr.play_music("ambience")
	check(mgr.music_stream_assigns == c0 + 2, "key switch crossfades to new track")
	mgr.set_muted(true)
	check(AudioServer.is_bus_mute(mgr.music_bus) and AudioServer.is_bus_mute(mgr.sfx_bus), "mute applies to both buses")
	mgr.set_muted(false)
	check(not AudioServer.is_bus_mute(mgr.music_bus) and not AudioServer.is_bus_mute(mgr.sfx_bus), "unmute restores both buses")
	mgr.queue_free()
	print("AUDIO_TEST failures=%d" % failures)
	quit(0 if failures == 0 else 1)
