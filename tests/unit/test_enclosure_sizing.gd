extends TestCase

const MEADOW := {"id": "enclosure_meadow", "size": [3, 3], "cost": {"coins": 200, "nature": 0}, "capacity": 3}
const TUNING := {"cost_ratio": 1.0, "max_cells": 100}


func _park_with_enclosure() -> ParkModel:
	var park := ParkModel.new(24, 12)
	park.place("o_1", "enclosure_meadow", Vector2i(3, 3), Vector2i(8, 8))
	return park


func test_capacity_scales_with_cells_and_never_drops_below_base() -> void:
	assert_eq(EnclosureSizing.capacity(MEADOW, 9), 3)
	assert_eq(EnclosureSizing.capacity(MEADOW, 12), 4)
	assert_eq(EnclosureSizing.capacity(MEADOW, 36), 12)


func test_cell_cost_and_value() -> void:
	assert_eq(EnclosureSizing.cell_cost(MEADOW, TUNING), {"coins": 23, "nature": 0})
	assert_eq(EnclosureSizing.value_coins(MEADOW, 0, TUNING), 200)
	assert_eq(EnclosureSizing.value_coins(MEADOW, 7, TUNING), 200 + 7 * 23)


func test_shape_candidates_are_free_neighbours() -> void:
	var park := _park_with_enclosure()
	park.place("o_2", "bench", Vector2i.ONE, Vector2i(11, 9))
	var candidates := park.shape_candidates("o_1")
	assert_eq(candidates.size(), 11)
	assert_true(candidates.has(Vector2i(11, 8)))
	assert_false(candidates.has(Vector2i(11, 9)))
	assert_false(candidates.has(Vector2i(12, 8)))


func test_add_cell_grows_free_shape_and_occupies() -> void:
	var park := _park_with_enclosure()
	assert_true(park.add_cell("o_1", Vector2i(11, 8)))
	assert_true(park.add_cell("o_1", Vector2i(12, 8)))
	assert_false(park.add_cell("o_1", Vector2i(14, 8)))
	assert_eq(park.cells_of("o_1").size(), 11)
	assert_eq(park.object_at(Vector2i(12, 8)), "o_1")


func test_remove_cell_keeps_shape_connected_and_base() -> void:
	var park := _park_with_enclosure()
	park.add_cell("o_1", Vector2i(11, 8))
	park.add_cell("o_1", Vector2i(12, 8))
	assert_false(park.remove_cell("o_1", Vector2i(11, 8)))
	assert_false(park.remove_cell("o_1", Vector2i(8, 8)))
	assert_true(park.remove_cell("o_1", Vector2i(12, 8)))
	assert_eq(park.object_at(Vector2i(12, 8)), "")


func test_move_carries_extra_cells_and_save_round_trips() -> void:
	var park := _park_with_enclosure()
	park.add_cell("o_1", Vector2i(11, 8))
	park.place("o_2", "bench", Vector2i.ONE, Vector2i(12, 6))
	assert_false(park.move("o_1", Vector2i(9, 6)))
	assert_true(park.move("o_1", Vector2i(8, 9)))
	assert_eq(park.object_at(Vector2i(11, 9)), "o_1")
	assert_eq(park.object_at(Vector2i(11, 8)), "")
	var restored := ParkModel.from_dict(park.to_dict())
	assert_eq(restored.cells_of("o_1"), park.cells_of("o_1"))
	assert_eq(restored.object_at(Vector2i(11, 9)), "o_1")
