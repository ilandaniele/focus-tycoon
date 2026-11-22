extends TestCase

const CHAIN := {"id": "c", "steps": [
	{"metric": "sessions_completed_total", "target": 2, "reward": {"coins": 10}},
	{"metric": "level", "target": 3, "reward": {"coins": 20}},
]}


func test_first_step_shows_progress() -> void:
	var entry := MissionChains.current(CHAIN, 0, {"sessions_completed_total": 1})
	assert_eq(entry["id"], "c")
	assert_eq(entry["step"], 0)
	assert_eq(entry["steps"], 2)
	assert_eq(entry["current"], 1.0)
	assert_false(entry["done"])
	assert_false(entry["finished"])


func test_claimed_step_moves_to_next() -> void:
	var entry := MissionChains.current(CHAIN, 1, {"sessions_completed_total": 5, "level": 3})
	assert_eq(entry["metric"], "level")
	assert_true(entry["done"])
	assert_eq(Ints.of(entry["reward"]), {"coins": 20})


func test_all_claimed_is_finished() -> void:
	var entry := MissionChains.current(CHAIN, 2, {})
	assert_true(entry["finished"])
	assert_false(entry.get("done", false))


func test_data_chains_use_known_metrics_and_rising_targets() -> void:
	GameState.reset_for_tests("user://test_mission_chains/", FakeClock.new())
	var metrics := Economy.totals()
	for chain: Dictionary in Config.objectives["mission_chains"]:
		var last_target_by_metric: Dictionary = {}
		for step: Dictionary in chain["steps"]:
			assert_true(metrics.has(step["metric"]), "%s: %s" % [chain["id"], step["metric"]])
			assert_true(float(step["target"]) > float(last_target_by_metric.get(step["metric"], 0)), chain["id"])
			last_target_by_metric[step["metric"]] = step["target"]
