extends TestCase

const DAY := 86400
const BASE := 1_763_200_000


func _session(ended_at: int, minutes: float, status: String = "completed", mode: String = "study") -> Dictionary:
	return {"id": "s", "mode": mode, "planned_min": int(minutes), "effective_min": minutes, "status": status,
		"started_at": ended_at - int(minutes * 60), "ended_at": ended_at, "cycle": 1}


func test_daily_focus_minutes_aggregates_seven_days_in_order() -> void:
	var sessions: Array = [
		_session(BASE, 25.0), _session(BASE + 100, 30.0),
		_session(BASE - DAY, 50.0),
		_session(BASE - 6 * DAY, 10.0),
		_session(BASE - 7 * DAY, 99.0),
	]
	var last_day := DayKey.of(BASE, 0)
	var result := Stats.daily_focus_minutes(sessions, last_day, 7, 0)
	assert_eq(result.size(), 7)
	assert_eq(result[0]["day"], DayKey.add_days(last_day, -6))
	assert_eq(result[6]["day"], last_day)
	assert_near(result[6]["minutes"], 55.0)
	assert_near(result[5]["minutes"], 50.0)
	assert_near(result[0]["minutes"], 10.0)
	assert_near(result[3]["minutes"], 0.0)


func test_daily_focus_minutes_respects_timezone() -> void:
	var late := _session(BASE - BASE % DAY + DAY - 60, 20.0)
	var last_day := DayKey.of(BASE, 0)
	assert_near(Stats.daily_focus_minutes([late], last_day, 1, 0)[0]["minutes"], 20.0)
	assert_near(Stats.daily_focus_minutes([late], last_day, 1, 3600)[0]["minutes"], 0.0)
	assert_near(Stats.daily_focus_minutes([late], DayKey.add_days(last_day, 1), 1, 3600)[0]["minutes"], 20.0)


func test_summary_counts_and_by_mode() -> void:
	var sessions: Array = [
		_session(BASE, 25.0, "completed", "study"),
		_session(BASE + 10, 10.0, "interrupted", "work"),
		_session(BASE + 20, 30.0, "completed", "study"),
		_session(BASE - 10 * DAY, 60.0, "completed", "reading"),
	]
	var day := DayKey.of(BASE, 0)
	var result := Stats.summary(sessions, DayKey.add_days(day, -6), day, 0)
	assert_near(result["total_min"], 65.0)
	assert_eq(result["completed"], 2)
	assert_eq(result["interrupted"], 1)
	assert_near(result["by_mode"]["study"], 55.0)
	assert_near(result["by_mode"]["work"], 10.0)
	assert_false(result["by_mode"].has("reading"))


func test_summary_empty() -> void:
	var result := Stats.summary([], "2025-11-01", "2025-11-30", 0)
	assert_near(result["total_min"], 0.0)
	assert_eq(result["completed"], 0)
	assert_true(result["by_mode"].is_empty())


func test_rewarded_focus_minutes_ignores_short_sessions_and_other_days() -> void:
	var sessions: Array = [_session(BASE, 25.0), _session(BASE, 3.0), _session(BASE - DAY, 40.0)]
	assert_near(Stats.rewarded_focus_minutes(sessions, DayKey.of(BASE, 0), 0, 5.0), 25.0)


func test_meditation_helpers() -> void:
	var sessions: Array = [
		{"seconds": 120, "ended_at": BASE},
		{"seconds": 30, "ended_at": BASE},
		{"seconds": 60, "ended_at": BASE - DAY},
		{"seconds": 300, "ended_at": BASE - DAY},
	]
	assert_near(Stats.meditation_minutes(sessions, DayKey.of(BASE, 0), 0, 60), 2.0)
	assert_eq(Stats.distinct_meditation_days(sessions, 0, 60), 2)
