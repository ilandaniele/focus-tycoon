extends TestCase

const MAP_SIDE := 20


func _cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in MAP_SIDE:
		for y in MAP_SIDE:
			cells.append(Vector2i(x, y))
	return cells


func test_ground_key_is_stable_per_cell() -> void:
	for cell in _cells():
		assert_eq(Scenery.ground_key(cell, true), Scenery.ground_key(cell, true))


func test_open_and_wild_ground_use_their_own_tiles() -> void:
	for cell in _cells():
		assert_true(Scenery.OPEN_GROUND.has(Scenery.ground_key(cell, true)), str(cell))
		assert_true(Scenery.WILD_GROUND.has(Scenery.ground_key(cell, false)), str(cell))


func test_open_ground_mixes_every_variant() -> void:
	var seen := {}
	for cell in _cells():
		seen[Scenery.ground_key(cell, true)] = true
	assert_eq(seen.size(), Scenery.OPEN_GROUND.size())


func test_cells_near_open_ground_never_get_tall_props() -> void:
	for cell in _cells():
		assert_false(Scenery.TALL_PROPS.has(Scenery.prop_key(cell, true)), str(cell))


func test_wild_cells_get_a_mix_of_props_and_empty_ground() -> void:
	var kinds := {}
	for cell in _cells():
		kinds[Scenery.prop_key(cell, false)] = true
	assert_true(kinds.has(""))
	assert_true(kinds.has("objects/tree_pine"))
	assert_true(kinds.has("objects/fern"))


func test_every_ground_key_is_a_tile() -> void:
	var tiles := ArtRegistry.tile_keys()
	for key in Scenery.ground_keys():
		assert_true(tiles.has(key), key)
