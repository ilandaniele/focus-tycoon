extends Node

const EXTRA_BUSES: Array[String] = ["Music", "Ambient", "SFX"]
const VOLUME_BUSES := {"vol_master": "Master", "vol_music": "Music", "vol_ambient": "Ambient", "vol_sfx": "SFX"}
const GENERATOR_BUFFER_S := 0.3

var _synth := AudioSynth.new()
var _ambient_player := AudioStreamPlayer.new()
var _sfx_player := AudioStreamPlayer.new()
var _playback: AudioStreamGeneratorPlayback
var _sampler: Callable
var _bell: AudioStreamWAV


func _ready() -> void:
	_ensure_buses()
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = AudioSynth.MIX_RATE
	generator.buffer_length = GENERATOR_BUFFER_S
	_ambient_player.stream = generator
	_ambient_player.bus = "Ambient"
	_sfx_player.bus = "SFX"
	add_child(_ambient_player)
	add_child(_sfx_player)
	set_process(false)
	GameState.state_loaded.connect(_apply_volumes)
	GameState.settings_changed.connect(_on_setting_changed)
	_apply_volumes()


func _process(_delta: float) -> void:
	var frames := _playback.get_frames_available()
	if frames > 0:
		_playback.push_buffer(_synth.fill(_sampler, frames))


func set_volume(bus: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(index, linear <= 0.0)


func play_ambient(id: String) -> void:
	stop_ambient()
	if id not in AudioSynth.AMBIENT_IDS or _is_headless():
		return
	_sampler = _synth.sampler_for(id)
	_ambient_player.play()
	_playback = _ambient_player.get_stream_playback() as AudioStreamGeneratorPlayback
	set_process(true)


func stop_ambient() -> void:
	set_process(false)
	_ambient_player.stop()


func play_sfx(id: String) -> void:
	if id != "bell" or _is_headless():
		return
	if _bell == null:
		_bell = AudioSynth.bell()
	_sfx_player.stream = _bell
	_sfx_player.play()


func _is_headless() -> bool:
	return DisplayServer.get_name() == "headless"


func _ensure_buses() -> void:
	for bus in EXTRA_BUSES:
		if AudioServer.get_bus_index(bus) >= 0:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus)
		AudioServer.set_bus_send(index, "Master")


func _apply_volumes() -> void:
	for key: String in VOLUME_BUSES:
		set_volume(VOLUME_BUSES[key], float(GameState.settings.get(key, 1.0)))


func _on_setting_changed(key: String) -> void:
	if VOLUME_BUSES.has(key):
		set_volume(VOLUME_BUSES[key], float(GameState.settings.get(key, 1.0)))
