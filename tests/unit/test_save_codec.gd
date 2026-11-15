extends TestCase

const SAMPLE := {"resources": {"balances": {"coins": 300, "nature": 10}}, "ratio": 0.5, "flag": true, "list": [1, 2]}


func test_roundtrip() -> void:
	var decoded := SaveCodec.decode(SaveCodec.encode(SAMPLE, 1234))
	assert_true(decoded["ok"])
	assert_eq(decoded["data"]["resources"]["balances"]["coins"], 300)
	assert_near(decoded["data"]["ratio"], 0.5)
	assert_eq(Ints.of(decoded["data"]["list"]), [1, 2])


func test_envelope_fields() -> void:
	var envelope: Dictionary = JSON.parse_string(SaveCodec.encode(SAMPLE, 1234))
	assert_eq(envelope["schema_version"], SaveCodec.SCHEMA_VERSION)
	assert_eq(envelope["saved_at"], 1234)
	assert_eq(envelope["checksum"], SaveCodec.checksum_of(SAMPLE))


func test_tampered_data_is_rejected() -> void:
	var envelope: Dictionary = JSON.parse_string(SaveCodec.encode(SAMPLE, 1234))
	envelope["data"]["resources"]["balances"]["coins"] = 999999
	var decoded := SaveCodec.decode(JSON.stringify(envelope))
	assert_false(decoded["ok"])
	assert_eq(decoded["error"], "checksum")


func test_tampered_checksum_is_rejected() -> void:
	var envelope: Dictionary = JSON.parse_string(SaveCodec.encode(SAMPLE, 1234))
	envelope["checksum"] = "0".repeat(64)
	assert_eq(SaveCodec.decode(JSON.stringify(envelope))["error"], "checksum")


func test_garbage_and_incomplete_are_rejected() -> void:
	assert_eq(SaveCodec.decode("not json {")["error"], "parse")
	assert_eq(SaveCodec.decode("")["error"], "parse")
	assert_eq(SaveCodec.decode("{\"data\": {}}")["error"], "format")


func test_newer_schema_is_rejected() -> void:
	var envelope: Dictionary = {"schema_version": SaveCodec.SCHEMA_VERSION + 1, "saved_at": 1,
		"checksum": SaveCodec.checksum_of(SAMPLE), "data": SAMPLE}
	assert_eq(SaveCodec.decode(JSON.stringify(envelope))["error"], "unsupported_version")


func test_checksum_ignores_int_float_difference() -> void:
	assert_eq(SaveCodec.checksum_of({"a": 5}), SaveCodec.checksum_of({"a": 5.0}))
