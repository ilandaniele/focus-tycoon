extends TestCase


func test_every_sfx_renders_audible_16_bit_audio() -> void:
	for id in AudioSynth.SFX_IDS:
		var stream := AudioSynth.sfx(id)
		assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS, id)
		assert_true(stream.data.size() > 0, id)
		assert_true(_peak(stream.data) > 1000, id + " is silent")


func test_pop_is_shorter_than_bell() -> void:
	assert_true(AudioSynth.sfx("pop").data.size() < AudioSynth.sfx("bell").data.size())


func _peak(data: PackedByteArray) -> int:
	var peak := 0
	for offset in range(0, data.size(), 2):
		peak = maxi(peak, absi(data.decode_s16(offset)))
	return peak
