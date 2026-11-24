extends TestCase


func before_each() -> void:
	GameState.reset_for_tests("user://test_mission_flow/", FakeClock.new())


func _chain(id: String) -> Dictionary:
	for entry: Dictionary in Economy.mission_chains():
		if entry["id"] == id:
			return entry
	return {}


func test_claim_requires_done_and_advances_once() -> void:
	assert_eq(Economy.claim_mission("collector")["error"], "not_done")
	Economy.grant("test:fund", {"coins": 1000}, "test")
	var cell := GameState.park.nearest_free_cell(Vector2i(3, 3), Vector2i(17, 17))
	var placed := ParkService.buy_and_place("enclosure_meadow", cell)
	assert_true(placed["ok"], placed["error"])
	var enclosure_uid: String = placed["uid"]
	GameState.park.add_animal("t_a_1", "rabbit", enclosure_uid)
	GameState.park.add_animal("t_a_2", "beaver", enclosure_uid)
	var coins_before := Economy.balance("coins")
	assert_true(_chain("collector")["done"])
	assert_true(Economy.claim_mission("collector")["ok"])
	assert_eq(Economy.balance("coins"), coins_before + 60)
	assert_eq(_chain("collector")["step"], 1)
	assert_eq(Economy.claim_mission("collector")["error"], "not_done")
	assert_eq(Economy.balance("coins"), coins_before + 60)


func test_unknown_chain_is_rejected() -> void:
	assert_eq(Economy.claim_mission("missing")["error"], "unknown_mission")


func test_every_chain_listed() -> void:
	assert_eq(Economy.mission_chains().size(), Config.objectives["mission_chains"].size())
