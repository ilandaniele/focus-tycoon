extends TestCase


func _build() -> ParkModel:
	return BenchmarkPark.build(int(Config.economy["park"]["map_size"]), Config.catalog, Config.species)


func test_fills_park_to_prd_target() -> void:
	var park := _build()
	assert_eq(park.objects.size(), BenchmarkPark.OBJECT_COUNT)
	assert_eq(park.animals.size(), BenchmarkPark.ANIMAL_COUNT)
	assert_eq(park.unlocked_size, park.map_size)


func test_every_animal_lives_in_matching_enclosure_within_capacity() -> void:
	var park := _build()
	for enclosure_uid: String in park.objects:
		var item: Dictionary = Config.item(park.objects[enclosure_uid]["item_id"])
		var residents := park.animals_in(enclosure_uid)
		if item["category"] != "enclosure":
			assert_true(residents.is_empty())
			continue
		assert_true(residents.size() <= int(item["capacity"]))
		for animal: Dictionary in residents:
			assert_eq(Config.species[animal["species_id"]]["biome"], item["biome"])


func test_objects_do_not_overlap() -> void:
	var park := _build()
	var covered: Dictionary = {}
	for entry: Dictionary in park.objects.values():
		var size: Vector2i = entry["size"]
		for x in size.x:
			for y in size.y:
				var cell: Vector2i = entry["cell"] + Vector2i(x, y)
				assert_false(covered.has(cell), "cell %s used twice" % cell)
				covered[cell] = true
				assert_eq(park.object_at(cell), entry["uid"])


func test_uses_every_species_and_item() -> void:
	var park := _build()
	var item_ids: Dictionary = {}
	for entry: Dictionary in park.objects.values():
		item_ids[entry["item_id"]] = true
	var species_ids: Dictionary = {}
	for animal: Dictionary in park.animals.values():
		species_ids[animal["species_id"]] = true
	assert_eq(item_ids.size(), Config.catalog.size())
	assert_eq(species_ids.size(), Config.species.size())


func test_demo_sessions_fill_last_week() -> void:
	var now := 1_800_000_000
	var focus := BenchmarkPark.demo_focus_sessions(now)
	var meditation := BenchmarkPark.demo_meditation_sessions(now)
	var week := Stats.daily_focus_minutes(focus, DayKey.of(now, 0), 7, 0)
	for day: Dictionary in week:
		assert_true(float(day["minutes"]) > 0.0, "every day has focus")
	assert_true(Stats.summary(focus, DayKey.add_days(DayKey.of(now, 0), -6), DayKey.of(now, 0), 0)["by_mode"].size() > 1, "several modes")
	assert_true(Stats.distinct_meditation_days(meditation, 0, 0) > 1, "meditation on several days")
	for session: Dictionary in focus + meditation:
		assert_true(int(session["ended_at"]) <= now, "no future sessions")
