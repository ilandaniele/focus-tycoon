class_name AudioSynth
extends RefCounted

const MIX_RATE := 11025
const SFX_RATE := 22050
const AMBIENT_IDS: Array[String] = ["rain", "forest", "brown", "cafe", "library"]
const SFX_IDS: Array[String] = ["bell", "pop", "cue_inhale", "cue_exhale", "cue_hold"]
const CUE_FREQUENCIES := {"cue_inhale": 523.25, "cue_exhale": 392.0, "cue_hold": 440.0}
const PHASE_CUES := {"inhale": "cue_inhale", "exhale": "cue_exhale", "hold": "cue_hold", "retain": "cue_hold"}

var _rng := RandomNumberGenerator.new()
var _brown: float = 0.0
var _rain_lowpass: float = 0.0
var _pink: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
var _drop_env: float = 0.0
var _drop_phase: float = 0.0
var _drop_freq: float = 0.0
var _chirp_env: float = 0.0
var _chirp_phase: float = 0.0
var _chirp_freq: float = 0.0
var _chirp_notes_left: int = 0
var _chirp_gap: int = 0
var _murmur: float = 0.0
var _murmur_swell: float = 0.0
var _clink_env: float = 0.0
var _clink_phase: float = 0.0
var _clink_freq: float = 0.0
var _rustle_env: float = 0.0
var _rustle_lowpass: float = 0.0


static func sfx(id: String) -> AudioStreamWAV:
	if id == "pop":
		return _render(0.18, _pop_sample)
	if CUE_FREQUENCIES.has(id):
		return _render(0.6, _cue_sample.bind(float(CUE_FREQUENCIES[id])))
	return _render(1.8, _bell_sample)


static func cue_for(phase_name: String) -> String:
	return PHASE_CUES.get(phase_name, "")


static func _cue_sample(time: float, frequency: float) -> float:
	var tone := sin(TAU * frequency * time) + 0.25 * sin(TAU * frequency * 2.0 * time)
	return tone * minf(1.0, time * 60.0) * exp(-time * 6.0) * 0.3


static func _bell_sample(time: float) -> float:
	var tone := sin(TAU * 660.0 * time) + 0.45 * sin(TAU * 1822.0 * time) * exp(-time * 2.0) + 0.2 * sin(TAU * 3564.0 * time) * exp(-time * 4.0)
	return tone * minf(1.0, time * 300.0) * exp(-time * 2.6) * 0.45


static func _pop_sample(time: float) -> float:
	var phase := TAU * (880.0 * time - 1200.0 * time * time)
	return sin(phase) * minf(1.0, time * 400.0) * exp(-time * 25.0) * 0.4


static func _render(seconds: float, sample_at: Callable) -> AudioStreamWAV:
	var count := int(SFX_RATE * seconds)
	var data := PackedByteArray()
	data.resize(count * 2)
	for index in count:
		var sample: float = sample_at.call(float(index) / SFX_RATE)
		data.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SFX_RATE
	stream.data = data
	return stream


func sampler_for(id: String) -> Callable:
	match id:
		"rain":
			return _rain_sample
		"forest":
			return _forest_sample
		"cafe":
			return _cafe_sample
		"library":
			return _library_sample
	return _brown_sample


func fill(sampler: Callable, frames: int) -> PackedVector2Array:
	var buffer := PackedVector2Array()
	buffer.resize(frames)
	for index in frames:
		var sample: float = sampler.call()
		buffer[index] = Vector2(sample, sample)
	return buffer


func _white() -> float:
	return _rng.randf_range(-1.0, 1.0)


func _brown_sample() -> float:
	_brown = (_brown + 0.02 * _white()) / 1.02
	return _brown * 1.8


func _rain_sample() -> float:
	_rain_lowpass += 0.35 * (_white() - _rain_lowpass)
	var sample := _rain_lowpass * 0.4
	if _drop_env < 0.001 and _rng.randf() < 14.0 / MIX_RATE:
		_drop_env = 1.0
		_drop_phase = 0.0
		_drop_freq = _rng.randf_range(900.0, 2600.0)
	if _drop_env >= 0.001:
		sample += sin(_drop_phase) * _drop_env * 0.22
		_drop_phase += TAU * _drop_freq / MIX_RATE
		_drop_env *= 0.992
	return sample


func _forest_sample() -> float:
	return _pink_noise() * 0.1 + _chirp_sample()


func _pink_noise() -> float:
	var white := _white()
	_pink[0] = 0.99886 * _pink[0] + white * 0.0555179
	_pink[1] = 0.99332 * _pink[1] + white * 0.0750759
	_pink[2] = 0.96900 * _pink[2] + white * 0.1538520
	_pink[3] = 0.86650 * _pink[3] + white * 0.3104856
	_pink[4] = 0.55000 * _pink[4] + white * 0.5329522
	_pink[5] = -0.7616 * _pink[5] - white * 0.0168980
	var total := _pink[0] + _pink[1] + _pink[2] + _pink[3] + _pink[4] + _pink[5] + _pink[6] + white * 0.5362
	_pink[6] = white * 0.115926
	return total * 0.2


func _chirp_sample() -> float:
	if _chirp_gap > 0:
		_chirp_gap -= 1
	elif _chirp_notes_left > 0:
		_chirp_notes_left -= 1
		_chirp_env = 1.0
		_chirp_phase = 0.0
		_chirp_freq = _rng.randf_range(2200.0, 3400.0)
		_chirp_gap = 1100
	elif _rng.randf() < 0.6 / MIX_RATE:
		_chirp_notes_left = _rng.randi_range(2, 4)
	if _chirp_env < 0.001:
		return 0.0
	var sample := sin(_chirp_phase) * _chirp_env * 0.18
	_chirp_phase += TAU * _chirp_freq / MIX_RATE
	_chirp_freq += 0.4
	_chirp_env *= 0.9985
	return sample


func _cafe_sample() -> float:
	_murmur += 0.08 * (_pink_noise() - _murmur)
	_murmur_swell += 0.00002 * (_rng.randf() - _murmur_swell)
	var sample := _murmur * (0.32 + 0.2 * _murmur_swell)
	if _clink_env < 0.001 and _rng.randf() < 0.25 / MIX_RATE:
		_clink_env = 1.0
		_clink_phase = 0.0
		_clink_freq = _rng.randf_range(2600.0, 3800.0)
	if _clink_env >= 0.001:
		sample += sin(_clink_phase) * _clink_env * 0.12
		_clink_phase += TAU * _clink_freq / MIX_RATE
		_clink_env *= 0.9993
	return sample


func _library_sample() -> float:
	var sample := _brown_sample() * 0.35
	if _rustle_env < 0.001 and _rng.randf() < 0.08 / MIX_RATE:
		_rustle_env = 1.0
	if _rustle_env >= 0.001:
		_rustle_lowpass += 0.5 * (_white() - _rustle_lowpass)
		sample += _rustle_lowpass * _rustle_env * 0.25
		_rustle_env *= 0.9996
	return sample
