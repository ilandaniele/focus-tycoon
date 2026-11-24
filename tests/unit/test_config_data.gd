extends TestCase


func test_economy_matches_gdd() -> void:
	var focus: Dictionary = Config.economy["focus"]
	assert_eq(focus["coins_per_min"], 2)
	assert_near(focus["nature_per_min"], 0.1)
	assert_near(focus["completion_bonus"], 0.2)
	assert_near(focus["interrupted_multiplier"], 0.5)
	assert_eq(focus["min_reward_minutes"], 5)
	assert_eq(focus["max_minutes"], 180)
	assert_eq(Ints.of(focus["presets"]), [15, 25, 45, 50, 90])
	assert_eq(focus["daily_tiers"].size(), 2)
	assert_eq(focus["daily_tiers"][0]["up_to_min"], 240)
	assert_eq(focus["daily_tiers"][1]["up_to_min"], 480)
	var meditation: Dictionary = Config.economy["meditation"]
	assert_eq(meditation["nature_per_min"], 2)
	assert_eq(meditation["min_seconds"], 60)
	assert_eq(meditation["daily_cap_min"], 60)
	assert_eq(Config.economy["levels"]["xp_thresholds"].size(), 15)
	assert_eq(Config.economy["levels"]["xp_thresholds"][6], 1400)
	assert_near(Config.economy["refund_ratio"], 0.5)
	assert_eq(Ints.of(Config.economy["starter_grant"]), {"coins": 300, "nature": 10})
	assert_eq(Ints.of(Config.economy["park"]), {"map_size": 24, "initial_unlocked": 12})


func test_catalog_matches_gdd() -> void:
	assert_eq(Config.catalog.size(), 55)
	assert_eq(Config.item("tree_oak")["cost"]["coins"], 25)
	assert_eq(Config.item("path_wood")["unlock_level"], 4)
	assert_eq(Ints.of(Config.item("fountain")["size"]), [2, 2])
	assert_eq(Config.item("statue")["cost"]["coins"], 500)
	assert_eq(Ints.of(Config.item("enclosure_ice")["cost"]), {"coins": 400, "nature": 20})
	assert_eq(Ints.of(Config.item("enclosure_savanna")["size"]), [4, 4])
	assert_eq(Config.item("enclosure_savanna")["capacity"], 2)
	assert_eq(Config.item("enclosure_meadow")["capacity"], 3)
	assert_true(Config.item("lantern_premium")["premium"])
	assert_eq(Config.items_in("enclosure").size(), 4)
	assert_eq(Config.items_in("path").size(), 3)
	assert_eq(Config.items_in("plant").size(), 35)
	assert_eq(Config.items_in("building").size(), 5)
	assert_eq(Config.item("hedge")["unlock_level"], 1)
	assert_true(Config.item("missing").is_empty())


func test_only_lantern_is_premium_and_enclosures_have_biome_and_capacity() -> void:
	for id: String in Config.catalog:
		var item: Dictionary = Config.catalog[id]
		assert_eq(item["premium"], id == "lantern_premium", id)
		if item["category"] == "enclosure":
			assert_true(item.has("biome") and item.has("capacity"), id)


func test_expansions_match_gdd() -> void:
	assert_eq(Config.expansions.map(func(e: Dictionary) -> int: return int(e["size"])), [16, 20, 24])
	assert_eq(Config.expansions.map(func(e: Dictionary) -> int: return int(e["cost"]["coins"])), [800, 2000, 4000])
	assert_eq(Config.expansions.map(func(e: Dictionary) -> int: return int(e["unlock_level"])), [3, 6, 10])


func test_species_match_gdd_and_are_visually_distinct() -> void:
	assert_eq(Config.species.keys(), ["rabbit", "penguin", "beaver", "koala", "elephant", "seal", "fox", "zebra", "hedgehog", "duck", "puffin", "squirrel", "owl", "flamingo", "lion", "hippo", "rhino"])
	assert_eq(Ints.of(Config.species["rabbit"]["cost"]), {"coins": 50, "nature": 10})
	assert_eq(Config.species["elephant"]["biome"], "savanna")
	assert_eq(Config.species["koala"]["unlock_level"], 5)
	var looks: Dictionary = {}
	for id: String in Config.species:
		var species: Dictionary = Config.species[id]
		looks["%s|%s|%s" % [species["speed"], species["scale"], species["color"]]] = true
		assert_true(str(species["color"]).begins_with("#"), id)
	assert_eq(looks.size(), Config.species.size())


func test_every_species_has_a_matching_enclosure_biome() -> void:
	var biomes: Array = Config.items_in("enclosure").map(func(item: Dictionary) -> String: return item["biome"])
	for id: String in Config.species:
		assert_true(biomes.has(Config.species[id]["biome"]), id)


func test_meditations_match_gdd() -> void:
	assert_eq(Config.meditations.keys(), ["box", "relax_478", "coherent", "rounds", "mindful", "pause"])
	assert_eq(Ints.of(Config.meditations["box"]["durations"]), [1, 2, 5])
	assert_eq(Config.meditations["box"]["phases"].size(), 4)
	assert_eq(Config.meditations["relax_478"]["phases"][1]["seconds"], 7)
	assert_eq(Ints.of(Config.meditations["coherent"]["durations"]), [2, 5, 10])
	assert_eq(Config.meditations["mindful"]["prompts"].size(), 6)
	assert_eq(Config.meditations["mindful"]["prompts"][5], "med.mindful.p6")
	assert_eq(Config.meditations["pause"]["prompts"], ["med.pause.p1", "med.pause.p2", "med.pause.p3"])
	assert_eq(Ints.of(Config.meditations["pause"]["durations"]), [1])
	assert_eq(Ints.of(Config.meditations["rounds"]["durations"]), [3, 6, 9])
	assert_eq(Config.meditations["rounds"]["warning"], "med.rounds.warning")


func test_pomodoro_presets_fit_focus_limits() -> void:
	var focus: Dictionary = Config.economy["focus"]
	var shapes: Array = focus["pomodoro"].map(func(p: Dictionary) -> Array: return [int(p["minutes"]), int(p["break_min"]), int(p["cycles"])])
	assert_eq(shapes, [[25, 5, 4], [50, 10, 2], [90, 20, 2]])
	for preset: Dictionary in focus["pomodoro"]:
		assert_true(int(preset["minutes"]) >= int(focus["min_minutes"]) and int(preset["minutes"]) <= int(focus["max_minutes"]), preset["id"])
		assert_true(Ints.of(focus["break_options"]).has(int(preset["break_min"])), preset["id"])
		assert_true(int(preset["cycles"]) <= int(focus["max_cycles"]), preset["id"])


func test_study_modes() -> void:
	assert_eq(Config.economy["modes"], ["study", "work", "reading", "languages", "review", "project"])


func test_objectives_match_gdd() -> void:
	assert_eq(Config.objectives["daily_count"], 3)
	assert_eq(Config.objectives["daily_pool"].size(), 5)
	assert_eq(Config.objectives["achievements"].size(), 6)
	var rewards: Dictionary = {}
	for def: Dictionary in Config.objectives["daily_pool"]:
		rewards[def["id"]] = def["reward"]
	assert_eq(Ints.of(rewards["focus_50_minutes"]), {"coins": 40, "nature": 5})
	assert_eq(Ints.of(rewards["place_3_objects"]), {"coins": 15})
	var achievement_ids: Array = Config.objectives["achievements"].map(func(def: Dictionary) -> String: return def["id"])
	assert_eq(achievement_ids, ["first_session", "focus_10_hours", "first_animal", "all_species", "meditate_7_days", "level_5"])
	assert_eq(Config.objectives["achievements"][1]["target"], 600)
