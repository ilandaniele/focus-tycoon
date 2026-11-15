extends TestCase


func test_evaluate_returns_reached_unearned_achievements() -> void:
	var defs: Array = Config.objectives["achievements"]
	var totals := {"sessions_completed_total": 3, "focus_minutes_total": 599.0, "animals_total": 1,
		"species_distinct": 1, "meditation_days_distinct": 2, "level": 5}
	var earned := Achievements.evaluate(defs, totals, {})
	earned.sort()
	assert_eq(earned, ["first_animal", "first_session", "level_5"])


func test_evaluate_skips_already_earned() -> void:
	var defs: Array = Config.objectives["achievements"]
	var totals := {"sessions_completed_total": 3, "level": 5}
	var earned := Achievements.evaluate(defs, totals, {"first_session": 100})
	assert_eq(earned, ["level_5"])


func test_evaluate_nothing_when_no_totals() -> void:
	assert_true(Achievements.evaluate(Config.objectives["achievements"], {}, {}).is_empty())


func test_all_defined_achievements_reachable() -> void:
	var totals := {"sessions_completed_total": 1, "focus_minutes_total": 600.0, "animals_total": 1,
		"species_distinct": 5, "meditation_days_distinct": 7, "level": 5}
	assert_eq(Achievements.evaluate(Config.objectives["achievements"], totals, {}).size(), 6)
