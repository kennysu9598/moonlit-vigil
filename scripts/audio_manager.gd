extends Node
## AudioMgr（autoload）——音频总线 + 双通道音乐 crossfade + 8 路音效池 + 总线静音。
## 总线在代码内建（Music/SFX 挂 Master），不依赖 default_bus_layout.tres。

const MUSIC := {
	"ambience": "res://assets/audio/moon_ambience_loop.wav",
	"battle": "res://assets/audio/battle_theme.ogg",
	"win": "res://assets/audio/win_theme.ogg",
	"lose": "res://assets/audio/lose_theme.ogg",
}
const MUSIC_DB := {"ambience": -18.0, "battle": -14.0, "win": -14.0, "lose": -14.0}
const POOL_SIZE := 8
const FADE_DB := -50.0

var music_stream_assigns := 0
var music_bus := -1
var sfx_bus := -1
var _music: Array[AudioStreamPlayer] = []
var _active := 0
var _current_key := ""
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _fades := {}

func _ready() -> void:
	music_bus = _ensure_bus("Music")
	sfx_bus = _ensure_bus("SFX")
	for i in range(2):
		var p := AudioStreamPlayer.new()
		p.bus = "Music"
		add_child(p)
		_music.append(p)
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)

func play_music(key: String, fade := 0.8) -> void:
	if key == _current_key or not MUSIC.has(key):return
	var path: String = MUSIC[key]
	if not ResourceLoader.exists(path):return
	var stream: AudioStream = load(path)
	if stream == null:return
	_make_looping(stream)
	_current_key = key
	music_stream_assigns += 1
	fade = maxf(fade, 0.01)
	var outgoing := _music[_active]
	_active = 1 - _active
	var incoming := _music[_active]
	_kill_fade(outgoing)
	_kill_fade(incoming)
	incoming.stream = stream
	incoming.volume_db = FADE_DB
	incoming.play()
	var t_in := create_tween()
	t_in.tween_property(incoming, "volume_db", float(MUSIC_DB.get(key, -14.0)), fade)
	_fades[incoming] = t_in
	if outgoing.playing:
		var t_out := create_tween()
		t_out.tween_property(outgoing, "volume_db", FADE_DB, fade)
		t_out.tween_callback(outgoing.stop)
		_fades[outgoing] = t_out

func play_sfx(name_value: String, pitch_jitter := 0.06) -> void:
	var path := "res://assets/audio/" + name_value + ".ogg"
	if not ResourceLoader.exists(path):return
	var stream: AudioStream = load(path)
	if stream == null:return
	var p := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stop()
	p.stream = stream
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()

func set_muted(muted: bool) -> void:
	AudioServer.set_bus_mute(music_bus, muted)
	AudioServer.set_bus_mute(sfx_bus, muted)

func is_muted() -> bool:
	return AudioServer.is_bus_mute(music_bus)

func _ensure_bus(bus_name: String) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:return idx
	AudioServer.add_bus()
	idx = AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")
	return idx

func _kill_fade(player: AudioStreamPlayer) -> void:
	if _fades.has(player):
		var t: Tween = _fades[player]
		if t != null and t.is_valid():t.kill()
		_fades.erase(player)

func _make_looping(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		var bytes_per_frame := 0
		if stream.format == AudioStreamWAV.FORMAT_8_BITS:bytes_per_frame = 1
		elif stream.format == AudioStreamWAV.FORMAT_16_BITS:bytes_per_frame = 2
		if bytes_per_frame > 0:
			if stream.stereo:bytes_per_frame *= 2
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = stream.data.size() / bytes_per_frame
