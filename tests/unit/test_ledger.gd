extends TestCase


func test_apply_is_idempotent_per_key() -> void:
	var ledger := Ledger.new()
	var first := ledger.apply("focus:a", {"coins": 10, "xp": 5}, "test", 100)
	var second := ledger.apply("focus:a", {"coins": 10, "xp": 5}, "test", 200)
	assert_true(first["ok"])
	assert_false(first["duplicate"])
	assert_true(second["ok"])
	assert_true(second["duplicate"])
	assert_eq(ledger.get_balance("coins"), 10)
	assert_eq(ledger.get_balance("xp"), 5)
	assert_true(ledger.has_key("focus:a"))


func test_insufficient_funds_is_all_or_nothing() -> void:
	var ledger := Ledger.new()
	ledger.apply("seed", {"coins": 10, "nature": 0}, "test", 1)
	var result := ledger.apply("buy:x", {"coins": -5, "nature": -1}, "test", 2)
	assert_false(result["ok"])
	assert_eq(result["error"], "insufficient_funds")
	assert_eq(ledger.get_balance("coins"), 10)
	assert_eq(ledger.get_balance("nature"), 0)
	assert_false(ledger.has_key("buy:x"))


func test_negative_xp_rejected() -> void:
	var ledger := Ledger.new()
	ledger.apply("seed", {"xp": 50}, "test", 1)
	var result := ledger.apply("bad", {"xp": -10}, "test", 2)
	assert_false(result["ok"])
	assert_eq(ledger.get_balance("xp"), 50)


func test_unknown_resource_rejected() -> void:
	var result := Ledger.new().apply("k", {"gems": 5}, "test", 1)
	assert_false(result["ok"])
	assert_eq(result["error"], "unknown_resource")


func test_can_afford() -> void:
	var ledger := Ledger.new()
	ledger.apply("seed", {"coins": 100, "nature": 5}, "test", 1)
	assert_true(ledger.can_afford({"coins": 100, "nature": 5}))
	assert_false(ledger.can_afford({"coins": 100, "nature": 6}))
	assert_true(ledger.can_afford({}))


func test_roundtrip_through_json_keeps_balances_and_keys() -> void:
	var ledger := Ledger.new()
	ledger.apply("starter_grant", {"coins": 300, "nature": 10}, "tutorial", 1000)
	ledger.apply("buy:o_1", {"coins": -25}, "buy", 1001)
	var restored := Ledger.from_dict(JSON.parse_string(JSON.stringify(ledger.to_dict())))
	assert_eq(restored.get_balance("coins"), 275)
	assert_eq(restored.get_balance("nature"), 10)
	assert_true(restored.has_key("starter_grant"))
	assert_true(restored.apply("buy:o_1", {"coins": -25}, "buy", 2000)["duplicate"])
	assert_eq(restored.get_balance("coins"), 275)


func test_log_capped_but_keys_kept() -> void:
	var ledger := Ledger.new()
	for index in Ledger.MAX_LOG + 20:
		ledger.apply("k%d" % index, {"coins": 1}, "test", index)
	assert_eq(ledger.to_dict()["log"].size(), Ledger.MAX_LOG)
	assert_true(ledger.has_key("k0"))
	assert_eq(ledger.get_balance("coins"), Ledger.MAX_LOG + 20)


func test_zero_amounts_are_left_out_of_log() -> void:
	var ledger := Ledger.new()
	ledger.apply("focus:a", {"coins": 12, "nature": 0, "xp": 5}, "focus", 1)
	assert_eq(ledger.entries()[0]["delta"], {"coins": 12, "xp": 5})


func test_all_zero_grant_marks_key_without_log_entry() -> void:
	var ledger := Ledger.new()
	var result := ledger.apply("meditation:m", {"coins": 0, "nature": 0, "xp": 0}, "meditation", 1)
	assert_true(result["ok"])
	assert_true(ledger.has_key("meditation:m"))
	assert_true(ledger.entries().is_empty())


func test_applied_count_grows_even_without_log_entry() -> void:
	var ledger := Ledger.new()
	ledger.apply("a", {"coins": 0}, "test", 1)
	ledger.apply("b", {"coins": 3}, "test", 2)
	assert_eq(ledger.applied_count(), 2)
