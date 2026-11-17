extends TestCase


func test_level_for_xp_at_thresholds() -> void:
	assert_eq(Progression.level_for_xp(Config.economy, 0), 1)
	assert_eq(Progression.level_for_xp(Config.economy, 99), 1)
	assert_eq(Progression.level_for_xp(Config.economy, 100), 2)
	assert_eq(Progression.level_for_xp(Config.economy, 249), 2)
	assert_eq(Progression.level_for_xp(Config.economy, 250), 3)
	assert_eq(Progression.level_for_xp(Config.economy, 1400), 7)
	assert_eq(Progression.level_for_xp(Config.economy, 9200), 15)
	assert_eq(Progression.level_for_xp(Config.economy, 999999), 15)


func test_xp_for_level() -> void:
	assert_eq(Progression.xp_for_level(Config.economy, 1), 0)
	assert_eq(Progression.xp_for_level(Config.economy, 5), 700)
	assert_eq(Progression.xp_for_level(Config.economy, 15), 9200)
	assert_eq(Progression.xp_for_level(Config.economy, 99), 9200)


func test_newly_unlocked_between_levels() -> void:
	var unlocked := Progression.newly_unlocked(Config.catalog, Config.species, 1, 2)
	for id in ["path_stone", "tree_pine", "sign_wood", "enclosure_ice", "penguin"]:
		assert_true(unlocked.has(id), id)
	assert_false(unlocked.has("rabbit"))
	assert_false(unlocked.has("lamp"))


func test_newly_unlocked_spans_several_levels_and_none_when_same() -> void:
	var unlocked := Progression.newly_unlocked(Config.catalog, Config.species, 4, 7)
	for id in ["panda", "fountain", "tree_cherry", "enclosure_savanna", "elephant"]:
		assert_true(unlocked.has(id), id)
	assert_false(unlocked.has("statue"))
	assert_true(Progression.newly_unlocked(Config.catalog, Config.species, 3, 3).is_empty())
