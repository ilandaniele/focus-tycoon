extends TestCase

const ONE := Vector2i(1, 1)
const TWO := Vector2i(2, 2)
const ENCLOSURE := Vector2i(3, 3)


func _park() -> ParkModel:
	return ParkModel.new(24, 12)


func test_unlocked_area_is_centered_square() -> void:
	var park := _park()
	assert_false(park.is_cell_unlocked(Vector2i(5, 6)))
	assert_true(park.is_cell_unlocked(Vector2i(6, 6)))
	assert_true(park.is_cell_unlocked(Vector2i(17, 17)))
	assert_false(park.is_cell_unlocked(Vector2i(18, 17)))
	park.unlocked_size = 16
	assert_true(park.is_cell_unlocked(Vector2i(4, 4)))
	assert_false(park.is_cell_unlocked(Vector2i(3, 4)))


func test_cannot_place_on_locked_cells_or_out_of_bounds() -> void:
	var park := _park()
	assert_false(park.can_place(ONE, Vector2i(0, 0)))
	assert_false(park.can_place(ONE, Vector2i(-1, 10)))
	assert_false(park.can_place(TWO, Vector2i(17, 17)))
	assert_true(park.can_place(TWO, Vector2i(16, 16)))
	assert_false(park.place("o_1", "fountain", TWO, Vector2i(17, 17)))


func test_overlap_is_rejected() -> void:
	var park := _park()
	assert_true(park.place("o_1", "fountain", TWO, Vector2i(6, 6)))
	assert_false(park.place("o_2", "bench", ONE, Vector2i(7, 7)))
	assert_false(park.place("o_1", "fountain", TWO, Vector2i(10, 10)))
	assert_true(park.place("o_2", "bench", ONE, Vector2i(8, 6)))
	assert_eq(park.object_at(Vector2i(7, 7)), "o_1")
	assert_eq(park.object_at(Vector2i(8, 6)), "o_2")
	assert_eq(park.object_at(Vector2i(9, 9)), "")


func test_move_respects_collisions_and_allows_overlapping_itself() -> void:
	var park := _park()
	park.place("o_1", "fountain", TWO, Vector2i(6, 6))
	park.place("o_2", "bench", ONE, Vector2i(10, 10))
	assert_false(park.move("o_1", Vector2i(9, 9)))
	assert_true(park.move("o_1", Vector2i(7, 6)))
	assert_eq(park.object_at(Vector2i(6, 6)), "")
	assert_eq(park.object_at(Vector2i(8, 7)), "o_1")
	assert_false(park.move("o_1", Vector2i(0, 0)))
	assert_false(park.move("missing", Vector2i(7, 7)))


func test_remove_frees_cells_and_returns_entry() -> void:
	var park := _park()
	park.place("o_1", "bench", ONE, Vector2i(6, 6))
	var removed := park.remove("o_1")
	assert_eq(removed["item_id"], "bench")
	assert_eq(park.object_at(Vector2i(6, 6)), "")
	assert_true(park.remove("o_1").is_empty())


func test_enclosure_with_animals_cannot_be_removed() -> void:
	var park := _park()
	park.place("o_1", "enclosure_meadow", ENCLOSURE, Vector2i(6, 6))
	park.add_animal("a_1", "rabbit", "o_1")
	assert_eq(park.animals_in("o_1").size(), 1)
	assert_true(park.remove("o_1").is_empty())
	assert_true(park.objects.has("o_1"))
	assert_eq(park.animals_in("o_2").size(), 0)


func test_to_dict_roundtrip_through_json() -> void:
	var park := _park()
	park.place("o_1", "enclosure_meadow", ENCLOSURE, Vector2i(6, 6))
	park.place("o_2", "tree_oak", ONE, Vector2i(11, 12))
	park.add_animal("a_1", "rabbit", "o_1")
	park.unlocked_size = 16
	var saved: Dictionary = JSON.parse_string(JSON.stringify(park.to_dict()))
	assert_eq(saved["objects"]["o_2"]["cell"], [11.0, 12.0])
	var restored := ParkModel.from_dict(saved)
	assert_eq(restored.unlocked_size, 16)
	assert_eq(restored.objects["o_2"]["cell"], Vector2i(11, 12))
	assert_eq(restored.objects["o_1"]["size"], ENCLOSURE)
	assert_eq(restored.object_at(Vector2i(8, 8)), "o_1")
	assert_eq(restored.animals_in("o_1").size(), 1)
	assert_false(restored.can_place(ONE, Vector2i(11, 12)))
	assert_eq(SaveCodec.checksum_of(restored.to_dict()), SaveCodec.checksum_of(park.to_dict()))


func test_nearest_free_cell_keeps_valid_start() -> void:
	var park := _park()
	assert_eq(park.nearest_free_cell(ENCLOSURE, Vector2i(8, 8)), Vector2i(8, 8))


func test_nearest_free_cell_moves_locked_start_inside_unlocked_area() -> void:
	var park := _park()
	var found := park.nearest_free_cell(ENCLOSURE, Vector2i(1, 1))
	assert_true(park.can_place(ENCLOSURE, found))
	assert_eq(found, Vector2i(6, 6))


func test_nearest_free_cell_skips_occupied_cells() -> void:
	var park := _park()
	park.place("o_1", "fountain", TWO, Vector2i(8, 8))
	var found := park.nearest_free_cell(ONE, Vector2i(8, 8))
	assert_true(park.can_place(ONE, found))
	assert_eq(maxi(absi(found.x - 8), absi(found.y - 8)), 1)


func test_nearest_free_cell_returns_start_when_nothing_fits() -> void:
	var park := ParkModel.new(4, 2)
	assert_eq(park.nearest_free_cell(ENCLOSURE, Vector2i(0, 0)), Vector2i(0, 0))


func test_entrance_runs_from_park_edge_to_map_edge() -> void:
	var park := ParkModel.new(30, 24)
	assert_eq(park.entrance_cells(), [Vector2i(15, 27), Vector2i(15, 28), Vector2i(15, 29)])
	assert_eq(park.gate_cell(), Vector2i(15, 26))
	assert_true(park.is_cell_unlocked(park.gate_cell()))
	park.unlocked_size = 30
	assert_true(park.entrance_cells().is_empty())


func test_grow_recenters_objects_and_keeps_occupancy() -> void:
	var park := _park()
	park.place("o_1", "fountain", TWO, Vector2i(6, 6))
	park.grow(30)
	assert_eq(park.map_size, 30)
	assert_eq(park.objects["o_1"]["cell"], Vector2i(9, 9))
	assert_eq(park.object_at(Vector2i(10, 10)), "o_1")
	assert_eq(park.object_at(Vector2i(6, 6)), "")
	assert_true(park.is_cell_unlocked(Vector2i(9, 9)))
	park.grow(20)
	assert_eq(park.map_size, 30)
