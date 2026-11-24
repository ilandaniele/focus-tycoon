extends TestCase

var clock: FakeClock


func before_each() -> void:
	clock = FakeClock.new()
	GameState.reset_for_tests("user://test_park_flow/", clock)


func _fund(coins: int, nature: int = 0, xp: int = 0) -> void:
	Economy.grant("test:fund:" + GameState.new_uid("f"), {"coins": coins, "nature": nature, "xp": xp}, "test")


func _snapshot() -> String:
	return SaveCodec.checksum_of({"park": GameState.park.to_dict(), "resources": GameState.ledger.to_dict(),
		"progress": GameState.progress})


func test_buy_place_save_reload_is_identical() -> void:
	Economy.grant("starter_grant", Config.economy["starter_grant"], "tutorial")
	var bought := ParkService.buy_and_place("tree_oak", Vector2i(15, 15))
	assert_true(bought["ok"])
	assert_eq(Economy.balance("coins"), 275)
	var before := _snapshot()
	assert_true(GameState.save_now())
	GameState.load_or_new()
	assert_eq(_snapshot(), before)
	assert_eq(GameState.park.object_at(Vector2i(15, 15)), bought["uid"])
	assert_eq(Economy.balance("coins"), 275)
	assert_true(GameState.ledger.has_key("buy:" + bought["uid"]))


func test_uids_are_never_reused_after_removal_and_reload() -> void:
	_fund(100)
	var first := ParkService.buy_and_place("path_dirt", Vector2i(15, 15))
	ParkService.remove_object(first["uid"])
	GameState.save_now()
	GameState.load_or_new()
	var second := ParkService.buy_and_place("path_dirt", Vector2i(15, 15))
	assert_true(first["uid"] != second["uid"])
	assert_true(second["ok"])


func test_buy_validation_errors() -> void:
	assert_eq(ParkService.buy_and_place("tree_oak", Vector2i(15, 15))["error"], "insufficient_funds")
	_fund(5000)
	assert_eq(ParkService.buy_and_place("fountain", Vector2i(15, 15))["error"], "locked_level")
	assert_eq(ParkService.buy_and_place("tree_oak", Vector2i(0, 0))["error"], "invalid_cell")
	assert_eq(ParkService.buy_and_place("lantern_premium", Vector2i(15, 15))["error"], "premium_required")
	assert_true(ParkService.buy_and_place("tree_oak", Vector2i(15, 15))["ok"])
	assert_eq(ParkService.buy_and_place("tree_oak", Vector2i(15, 15))["error"], "invalid_cell")
	assert_eq(Economy.balance("coins"), 5000 - 25)


func test_premium_item_with_entitlement() -> void:
	GameState.progress["entitlements"].append("premium")
	var result := ParkService.buy_and_place("lantern_premium", Vector2i(15, 15))
	assert_true(result["ok"])
	assert_eq(Economy.balance("coins"), 0)


func test_failed_purchase_changes_nothing() -> void:
	_fund(20)
	var result := ParkService.buy_and_place("tree_oak", Vector2i(15, 15))
	assert_false(result["ok"])
	assert_eq(Economy.balance("coins"), 20)
	assert_true(GameState.park.objects.is_empty())
	assert_true(GameState.progress["objects_placed_by_day"].is_empty())


func test_remove_refunds_half_of_coins_once() -> void:
	_fund(100)
	var uid: String = ParkService.buy_and_place("tree_oak", Vector2i(15, 15))["uid"]
	var removed := ParkService.remove_object(uid)
	assert_true(removed["ok"])
	assert_eq(removed["refund"], 12)
	assert_eq(Economy.balance("coins"), 100 - 25 + 12)
	assert_true(GameState.ledger.has_key("refund:" + uid))
	assert_false(ParkService.remove_object(uid)["ok"])
	assert_eq(Economy.balance("coins"), 87)


func test_move_object() -> void:
	_fund(100)
	var uid: String = ParkService.buy_and_place("tree_oak", Vector2i(15, 15))["uid"]
	assert_true(ParkService.move_object(uid, Vector2i(16, 16)))
	assert_false(ParkService.move_object(uid, Vector2i(0, 0)))
	assert_eq(GameState.park.object_at(Vector2i(16, 16)), uid)


func test_adopt_flow_and_errors() -> void:
	_fund(2000, 200, 250)
	var enclosure: String = ParkService.buy_and_place("enclosure_meadow", Vector2i(13, 13))["uid"]
	assert_eq(ParkService.adopt("rabbit", "missing")["error"], "no_enclosure")
	assert_eq(ParkService.adopt("penguin", enclosure)["error"], "no_enclosure")
	assert_eq(ParkService.enclosures_for("rabbit"), [enclosure])
	assert_eq(ParkService.enclosures_for("penguin"), [])
	for index in 3:
		assert_true(ParkService.adopt("rabbit", enclosure)["ok"], "rabbit %d" % index)
	assert_eq(ParkService.adopt("rabbit", enclosure)["error"], "enclosure_full")
	assert_eq(ParkService.enclosures_for("rabbit"), [])
	assert_eq(GameState.park.animals_in(enclosure).size(), 3)
	assert_eq(ParkService.remove_object(enclosure)["error"], "enclosure_not_empty")
	assert_true(GameState.park.objects.has(enclosure))


func test_adopt_requires_level_and_funds() -> void:
	_fund(200, 10)
	var enclosure: String = ParkService.buy_and_place("enclosure_meadow", Vector2i(13, 13))["uid"]
	assert_eq(ParkService.adopt("beaver", enclosure)["error"], "locked_level")
	assert_eq(ParkService.adopt("rabbit", enclosure)["error"], "insufficient_funds")
	_fund(100)
	assert_true(ParkService.adopt("rabbit", enclosure)["ok"])
	assert_eq(Economy.balance("coins"), 200 - 200 + 100 - 50)
	assert_eq(Economy.balance("nature"), 10 - 10 + 30)


func test_buy_expansion() -> void:
	_fund(5000)
	assert_eq(ParkService.buy_expansion("expand_1")["error"], "locked_level")
	_fund(0, 0, 250)
	assert_true(ParkService.buy_expansion("expand_1")["ok"])
	assert_eq(GameState.park.unlocked_size, 16)
	assert_eq(ParkService.buy_expansion("expand_1")["error"], "already_owned")
	assert_true(ParkService.buy_and_place("path_dirt", Vector2i(9, 9))["ok"])
	assert_eq(Economy.balance("coins"), 5000 - 800 - 3)


func test_expansion_survives_reload() -> void:
	_fund(1000, 0, 250)
	ParkService.buy_expansion("expand_1")
	GameState.save_now()
	GameState.load_or_new()
	assert_eq(GameState.park.unlocked_size, 16)
	assert_eq(ParkService.buy_expansion("expand_1")["error"], "already_owned")


func test_level_up_signal_lists_unlocked_ids() -> void:
	var seen: Array = []
	var on_level_up := func(level: int, unlocked: Array) -> void: seen.append([level, unlocked])
	Economy.level_up.connect(on_level_up)
	_fund(0, 0, 100)
	Economy.level_up.disconnect(on_level_up)
	assert_eq(seen.size(), 1)
	assert_eq(seen[0][0], 2)
	assert_true(seen[0][1].has("penguin"))
	assert_true(seen[0][1].has("path_stone"))


func test_first_animal_achievement_is_granted_once() -> void:
	_fund(1000, 100)
	var enclosure: String = ParkService.buy_and_place("enclosure_meadow", Vector2i(13, 13))["uid"]
	var nature_before := Economy.balance("nature")
	ParkService.adopt("rabbit", enclosure)
	assert_true(GameState.progress["achievements"].has("first_animal"))
	assert_eq(Economy.balance("nature"), nature_before - 10 + 30)
	ParkService.adopt("rabbit", enclosure)
	assert_eq(Economy.balance("nature"), nature_before - 20 + 30)
