extends TestCase

const SIMULATED_DAYS := 30


func _day_focus_reward(session_minutes: Array, completed: bool = true) -> Dictionary:
	var rewarded := 0.0
	var totals := {"coins": 0, "nature": 0, "xp": 0}
	for minutes: float in session_minutes:
		var reward := RewardCalculator.focus_reward(Config.economy, minutes, completed, rewarded)
		rewarded += reward["counted_min"]
		for resource: String in totals:
			totals[resource] += reward[resource]
	return totals


func _repeat(minutes: float, times: int) -> Array:
	var sessions: Array = []
	sessions.resize(times)
	sessions.fill(minutes)
	return sessions


func test_medium_profile_thirty_days_respects_cap_and_level_pace() -> void:
	var max_coins := RewardCalculator.max_daily_focus_coins(Config.economy)
	var xp := 0
	var level_7_day := 0
	for day in range(1, SIMULATED_DAYS + 1):
		var focus := _day_focus_reward(_repeat(30.0, 4))
		var meditation := RewardCalculator.meditation_reward(Config.economy, 300, 0.0)
		assert_true(focus["coins"] <= max_coins, "day %d" % day)
		xp += focus["xp"] + meditation["xp"]
		if level_7_day == 0 and Progression.level_for_xp(Config.economy, xp) >= 7:
			level_7_day = day
	assert_true(level_7_day >= 7, "level 7 reached on day %d" % level_7_day)
	assert_true(level_7_day > 0, "level 7 reachable within the simulation")


func test_medium_profile_daily_income_matches_gdd() -> void:
	var focus := _day_focus_reward(_repeat(30.0, 4))
	var meditation := RewardCalculator.meditation_reward(Config.economy, 300, 0.0)
	assert_eq(focus["coins"] + meditation["coins"], 293)
	assert_eq(focus["nature"] + meditation["nature"], 22)
	assert_eq(focus["xp"] + meditation["xp"], 125)


func test_intense_and_spam_profiles_never_exceed_daily_cap() -> void:
	var max_coins := RewardCalculator.max_daily_focus_coins(Config.economy)
	assert_eq(_day_focus_reward(_repeat(30.0, 16))["coins"], max_coins)
	assert_true(_day_focus_reward(_repeat(180.0, 10))["coins"] <= max_coins)
	assert_true(_day_focus_reward(_repeat(5.0, 300))["coins"] <= max_coins)
	assert_true(_day_focus_reward(_repeat(30.0, 60), false)["coins"] <= max_coins)


func test_many_short_sessions_do_not_beat_one_long_session() -> void:
	var split := _day_focus_reward(_repeat(5.0, 50))
	var single := RewardCalculator.focus_reward(Config.economy, 250.0, true, 0.0)
	assert_true(split["coins"] <= single["coins"])
	assert_true(split["xp"] <= single["xp"])
	assert_true(split["nature"] <= single["nature"])


func test_interrupting_never_pays_more_than_completing() -> void:
	for minutes in [5.0, 12.5, 30.0, 90.0, 180.0]:
		var completed := RewardCalculator.focus_reward(Config.economy, minutes, true, 0.0)
		var interrupted := RewardCalculator.focus_reward(Config.economy, minutes, false, 0.0)
		assert_true(interrupted["coins"] <= completed["coins"])
		assert_true(interrupted["xp"] <= completed["xp"])
