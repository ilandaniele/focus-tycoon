extends TestCase

var clock: FakeClock


func before_each() -> void:
	MeditationService.finish(false)
	clock = FakeClock.new()
	GameState.reset_for_tests("user://test_economy_flow/", clock)


func _advance_to_day_with(objective_id: String) -> Dictionary:
	for attempt in 40:
		for entry: Dictionary in Economy.objectives_today():
			if entry["id"] == objective_id:
				return entry
		clock.advance(DayKey.SECONDS_PER_DAY)
	return {}


func test_starter_grant_twice_grants_once() -> void:
	var first := Economy.grant("starter_grant", Config.economy["starter_grant"], "tutorial")
	var second := Economy.grant("starter_grant", Config.economy["starter_grant"], "tutorial")
	assert_false(first["duplicate"])
	assert_true(second["duplicate"])
	assert_eq(Economy.balance("coins"), 300)
	assert_eq(Economy.balance("nature"), 10)


func test_spend_is_all_or_nothing_and_idempotent() -> void:
	Economy.grant("seed", {"coins": 30}, "test")
	assert_eq(Economy.spend("buy:x", {"coins": 50}, "test")["error"], "insufficient_funds")
	assert_eq(Economy.balance("coins"), 30)
	assert_true(Economy.spend("buy:y", {"coins": 10, "nature": 0}, "test")["ok"])
	assert_true(Economy.spend("buy:y", {"coins": 10, "nature": 0}, "test")["duplicate"])
	assert_eq(Economy.balance("coins"), 20)


func test_resources_changed_emitted_on_grant_only_when_applied() -> void:
	var emitted: Array = []
	var on_change := func(balances: Dictionary) -> void: emitted.append(balances["coins"])
	Economy.resources_changed.connect(on_change)
	Economy.grant("a", {"coins": 5}, "test")
	Economy.grant("a", {"coins": 5}, "test")
	Economy.resources_changed.disconnect(on_change)
	assert_eq(emitted, [5])


func test_daily_objective_can_be_claimed_once() -> void:
	var entry := _advance_to_day_with("place_3_objects")
	assert_false(entry.is_empty())
	assert_eq(Economy.claim_objective("place_3_objects")["error"], "not_done")
	Economy.grant("seed", {"coins": 100}, "test")
	for index in 3:
		assert_true(ParkService.buy_and_place("path_dirt", Vector2i(10 + index, 10))["ok"])
	assert_eq(Economy.day_metrics(GameState.today())["objects_placed"], 3)
	var coins_before := Economy.balance("coins")
	assert_true(Economy.claim_objective("place_3_objects")["ok"])
	assert_eq(Economy.balance("coins"), coins_before + 15)
	assert_eq(Economy.claim_objective("place_3_objects")["error"], "already_claimed")
	assert_eq(Economy.balance("coins"), coins_before + 15)


func test_claim_unknown_objective_is_not_done() -> void:
	assert_false(Economy.claim_objective("nope")["ok"])


func test_objectives_today_are_three_and_stable() -> void:
	var first := Economy.objectives_today()
	assert_eq(first.size(), 3)
	assert_eq(Economy.objectives_today().map(func(e: Dictionary) -> String: return e["id"]),
		first.map(func(e: Dictionary) -> String: return e["id"]))
	for entry: Dictionary in first:
		assert_false(entry["done"])
		assert_false(entry["claimed"])


func test_focus_objective_progress_and_claim() -> void:
	var entry := _advance_to_day_with("complete_1_session")
	assert_false(entry.is_empty())
	FocusService.start(25, "study")
	clock.advance(25 * 60)
	FocusService.tick_now()
	assert_true(Economy.claim_objective("complete_1_session")["ok"])
	assert_eq(Economy.balance("coins"), 60 + 20 + 30)


func test_meditation_streak_achievement_after_seven_distinct_days() -> void:
	for day in 7:
		MeditationService.start("pause", 1)
		clock.advance(60)
		MeditationService.finish(true)
		clock.advance(DayKey.SECONDS_PER_DAY)
	assert_true(GameState.progress["achievements"].has("meditate_7_days"))
	assert_eq(Economy.totals()["meditation_days_distinct"], 7)
	assert_eq(Economy.balance("nature"), 7 * 2 + 50)


func test_level_5_achievement_grants_coins_once() -> void:
	Economy.grant("xp1", {"xp": 700}, "test")
	assert_eq(Economy.level(), 5)
	assert_eq(Economy.balance("coins"), 100)
	Economy.grant("xp2", {"xp": 10}, "test")
	assert_eq(Economy.balance("coins"), 100)
