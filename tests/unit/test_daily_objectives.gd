extends TestCase


func test_pick_is_deterministic_and_unique() -> void:
	var pool: Array = Config.objectives["daily_pool"]
	var first := DailyObjectives.pick(pool, "2025-11-15", 3)
	var second := DailyObjectives.pick(pool, "2025-11-15", 3)
	assert_eq(first, second)
	assert_eq(first.size(), 3)
	var unique: Dictionary = {}
	for id in first:
		unique[id] = true
	assert_eq(unique.size(), 3)


func test_pick_varies_across_days_and_uses_whole_pool() -> void:
	var pool: Array = Config.objectives["daily_pool"]
	var seen: Dictionary = {}
	var distinct_sets: Dictionary = {}
	var day := "2025-11-01"
	for offset in 30:
		var ids := DailyObjectives.pick(pool, day, 3)
		distinct_sets[str(ids)] = true
		for id in ids:
			seen[id] = true
		day = DayKey.add_days(day, 1)
	assert_eq(seen.size(), pool.size())
	assert_true(distinct_sets.size() > 5)


func test_pick_count_is_clamped_to_pool() -> void:
	var pool: Array = Config.objectives["daily_pool"]
	assert_eq(DailyObjectives.pick(pool, "2025-11-15", 99).size(), pool.size())
	assert_eq(DailyObjectives.pick([], "2025-11-15", 3).size(), 0)


func test_progress() -> void:
	var def: Dictionary = {"id": "x", "metric": "focus_minutes", "target": 50}
	var partial := DailyObjectives.progress(def, {"focus_minutes": 20.5})
	assert_near(partial["current"], 20.5)
	assert_eq(partial["target"], 50)
	assert_false(partial["done"])
	assert_true(DailyObjectives.progress(def, {"focus_minutes": 50})["done"])
	assert_false(DailyObjectives.progress(def, {})["done"])
