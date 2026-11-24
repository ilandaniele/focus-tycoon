extends TestCase

const ONE := Vector2i(1, 1)
const TUNING := {"base": 1, "per_attraction": 2, "max": 6}


func _park() -> ParkModel:
	return ParkModel.new(24, 24)


func _path(park: ParkModel, cells: Array) -> void:
	for cell: Vector2i in cells:
		park.place("p_%d_%d" % [cell.x, cell.y], "path_dirt", ONE, cell)


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	return rng


func test_path_cells_are_only_path_items() -> void:
	var park := _park()
	_path(park, [Vector2i(2, 2), Vector2i(3, 2)])
	park.place("o_1", "bench", ONE, Vector2i(5, 5))
	var cells := VisitorRoutes.path_cells(park, Config.catalog)
	assert_eq(cells.size(), 2)
	assert_true(cells.has(Vector2i(2, 2)) and cells.has(Vector2i(3, 2)))


func test_next_cell_keeps_walking_forward_on_a_line() -> void:
	var park := _park()
	_path(park, [Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2)])
	var cells := VisitorRoutes.path_cells(park, Config.catalog)
	for attempt in 10:
		assert_eq(VisitorRoutes.next_cell(Vector2i(3, 2), Vector2i(2, 2), cells, _rng()), Vector2i(4, 2))


func test_next_cell_turns_back_at_dead_end_and_stays_when_isolated() -> void:
	var park := _park()
	_path(park, [Vector2i(2, 2), Vector2i(3, 2), Vector2i(9, 9)])
	var cells := VisitorRoutes.path_cells(park, Config.catalog)
	assert_eq(VisitorRoutes.next_cell(Vector2i(3, 2), Vector2i(2, 2), cells, _rng()), Vector2i(2, 2))
	assert_eq(VisitorRoutes.next_cell(Vector2i(9, 9), Vector2i(9, 9), cells, _rng()), Vector2i(9, 9))


func test_next_cell_never_moves_diagonally() -> void:
	var park := _park()
	_path(park, [Vector2i(2, 2), Vector2i(3, 3)])
	var cells := VisitorRoutes.path_cells(park, Config.catalog)
	assert_eq(VisitorRoutes.next_cell(Vector2i(2, 2), Vector2i(2, 2), cells, _rng()), Vector2i(2, 2))


func test_viewing_cells_touch_enclosures_with_animals_or_buildings() -> void:
	var park := _park()
	park.place("e_1", "enclosure_meadow", Vector2i(3, 3), Vector2i(4, 4))
	park.add_animal("a_1", "rabbit", "e_1")
	park.place("e_2", "enclosure_ice", Vector2i(3, 3), Vector2i(12, 4))
	park.place("s_1", "snack_stand", Vector2i(2, 2), Vector2i(4, 12))
	_path(park, [Vector2i(3, 5), Vector2i(2, 5), Vector2i(11, 5), Vector2i(6, 12), Vector2i(7, 7)])
	var views := VisitorRoutes.viewing_cells(park, Config.catalog)
	assert_true(views.has(Vector2i(3, 5)), "next to enclosure with animal")
	assert_false(views.has(Vector2i(2, 5)), "two cells away")
	assert_false(views.has(Vector2i(11, 5)), "empty enclosure")
	assert_true(views.has(Vector2i(6, 12)), "next to building")
	assert_false(views.has(Vector2i(7, 7)), "diagonal corner only")


func test_visitor_count_grows_with_attractions_and_caps() -> void:
	var park := _park()
	assert_eq(VisitorRoutes.visitor_count(park, Config.catalog, TUNING), 0, "no paths")
	_path(park, [Vector2i(2, 2)])
	assert_eq(VisitorRoutes.visitor_count(park, Config.catalog, TUNING), 1)
	park.place("s_1", "snack_stand", Vector2i(2, 2), Vector2i(4, 4))
	assert_eq(VisitorRoutes.visitor_count(park, Config.catalog, TUNING), 3)
	park.place("e_1", "enclosure_meadow", Vector2i(3, 3), Vector2i(8, 8))
	assert_eq(VisitorRoutes.visitor_count(park, Config.catalog, TUNING), 3, "empty enclosure draws nobody")
	park.add_animal("a_1", "rabbit", "e_1")
	assert_eq(VisitorRoutes.visitor_count(park, Config.catalog, TUNING), 5)
	park.place("s_2", "gift_shop", Vector2i(2, 2), Vector2i(14, 14))
	assert_eq(VisitorRoutes.visitor_count(park, Config.catalog, TUNING), 6)


func test_visitor_tuning_lives_in_data() -> void:
	var tuning: Dictionary = Config.economy["visitors"]
	for key in ["base", "per_attraction", "max", "walk_px_per_second", "look_seconds", "look_chance", "variants"]:
		assert_true(tuning.has(key), key)
	for variant: String in tuning["variants"]:
		assert_true(ArtRegistry.get_texture("visitors/" + variant) != null, variant)
