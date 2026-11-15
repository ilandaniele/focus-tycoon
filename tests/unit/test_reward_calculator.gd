extends TestCase


func test_completed_session_includes_bonus_on_coins_only() -> void:
	var reward := RewardCalculator.focus_reward(Config.economy, 25.0, true, 0.0)
	assert_eq(reward["coins"], 60)
	assert_eq(reward["nature"], 2)
	assert_eq(reward["xp"], 25)
	assert_near(reward["counted_min"], 25.0)


func test_interrupted_session_is_halved_without_bonus() -> void:
	var reward := RewardCalculator.focus_reward(Config.economy, 10.0, false, 0.0)
	assert_eq(reward["coins"], 10)
	assert_eq(reward["nature"], 0)
	assert_eq(reward["xp"], 5)


func test_under_minimum_gives_nothing() -> void:
	var reward := RewardCalculator.focus_reward(Config.economy, 4.9, true, 0.0)
	assert_eq(reward["coins"], 0)
	assert_eq(reward["xp"], 0)
	assert_near(reward["counted_min"], 0.0)
	assert_eq(RewardCalculator.focus_reward(Config.economy, 5.0, true, 0.0)["coins"], 12)


func test_session_crossing_first_threshold_is_split() -> void:
	var reward := RewardCalculator.focus_reward(Config.economy, 20.0, true, 230.0)
	assert_eq(reward["coins"], 36)
	assert_eq(reward["xp"], 15)
	assert_near(reward["counted_min"], 20.0)


func test_session_crossing_second_threshold_is_split() -> void:
	var reward := RewardCalculator.focus_reward(Config.economy, 20.0, true, 470.0)
	assert_eq(reward["coins"], 12)
	assert_eq(reward["xp"], 5)


func test_beyond_daily_cap_gives_nothing_but_counts_minutes() -> void:
	var reward := RewardCalculator.focus_reward(Config.economy, 30.0, true, 480.0)
	assert_eq(reward["coins"], 0)
	assert_eq(reward["xp"], 0)
	assert_near(reward["counted_min"], 30.0)


func test_second_tier_pays_half() -> void:
	assert_eq(RewardCalculator.focus_reward(Config.economy, 30.0, true, 240.0)["coins"], 36)


func test_max_daily_focus_coins() -> void:
	assert_eq(RewardCalculator.max_daily_focus_coins(Config.economy), 864)


func test_meditation_below_minimum_seconds_gives_nothing() -> void:
	var reward := RewardCalculator.meditation_reward(Config.economy, 59, 0.0)
	assert_eq(reward["coins"], 0)
	assert_eq(reward["nature"], 0)
	assert_near(reward["counted_min"], 0.0)


func test_meditation_reward() -> void:
	var reward := RewardCalculator.meditation_reward(Config.economy, 120, 0.0)
	assert_eq(reward["coins"], 2)
	assert_eq(reward["nature"], 4)
	assert_eq(reward["xp"], 2)
	assert_near(reward["counted_min"], 2.0)
	assert_eq(RewardCalculator.meditation_reward(Config.economy, 60, 0.0)["nature"], 2)


func test_meditation_daily_cap() -> void:
	var partial := RewardCalculator.meditation_reward(Config.economy, 120, 59.0)
	assert_near(partial["counted_min"], 1.0)
	assert_eq(partial["coins"], 1)
	assert_eq(partial["nature"], 2)
	var capped := RewardCalculator.meditation_reward(Config.economy, 120, 60.0)
	assert_eq(capped["coins"], 0)
	assert_eq(capped["xp"], 0)
