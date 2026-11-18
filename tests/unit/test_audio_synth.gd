extends TestCase


func test_every_sfx_renders_audible_16_bit_audio() -> void:
	for id in AudioSynth.SFX_IDS:
		var stream := AudioSynth.sfx(id)
		assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS, id)
		assert_true(stream.data.size() > 0, id)
		assert_true(_peak(stream.data) > 1000, id + " is silent")


func test_pop_is_shorter_than_bell() -> void:
	assert_true(AudioSynth.sfx("pop").data.size() < AudioSynth.sfx("bell").data.size())


func test_every_ambient_is_audible_and_unclipped() -> void:
	assert_eq(AudioSynth.AMBIENT_IDS, ["rain", "forest", "brown", "cafe", "library"])
	for id in AudioSynth.AMBIENT_IDS:
		var synth := AudioSynth.new()
		var buffer := synth.fill(synth.sampler_for(id), AudioSynth.MIX_RATE * 4)
		var peak := 0.0
		for frame in buffer:
			peak = maxf(peak, absf(frame.x))
		assert_true(peak > 0.02, id + " is silent")
		assert_true(peak <= 1.0, id + " clips")


func test_ambient_samplers_differ() -> void:
	var synth := AudioSynth.new()
	var seen: Dictionary = {}
	for id in AudioSynth.AMBIENT_IDS:
		seen[synth.sampler_for(id).get_method()] = true
	assert_eq(seen.size(), AudioSynth.AMBIENT_IDS.size())


func test_phase_cues_are_short_and_distinct() -> void:
	var renders: Dictionary = {}
	for id in ["cue_inhale", "cue_exhale", "cue_hold"]:
		assert_true(id in AudioSynth.SFX_IDS, id)
		var stream := AudioSynth.sfx(id)
		assert_true(stream.data.size() < AudioSynth.sfx("bell").data.size(), id)
		assert_true(_peak(stream.data) > 1000, id + " is silent")
		renders[hash(stream.data)] = true
	assert_eq(renders.size(), 3)
	assert_eq(AudioSynth.cue_for("inhale"), "cue_inhale")
	assert_eq(AudioSynth.cue_for("retain"), "cue_hold")
	assert_eq(AudioSynth.cue_for("rest"), "")


func _peak(data: PackedByteArray) -> int:
	var peak := 0
	for offset in range(0, data.size(), 2):
		peak = maxi(peak, absi(data.decode_s16(offset)))
	return peak
