extends TestCase


func _layer() -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.tile_set = ArtRegistry.build_tileset()
	return layer


func test_cells_of_covers_footprint_row_major() -> void:
	var cells := IsoGrid.cells_of(Vector2i(2, 3), Vector2i(2, 2))
	assert_eq(cells.size(), 4)
	assert_true(cells.has(Vector2i(2, 3)) and cells.has(Vector2i(3, 4)))
	assert_false(cells.has(Vector2i(4, 3)))


func test_footprint_center_of_single_cell_is_cell_center() -> void:
	var layer := _layer()
	var cell := Vector2i(5, 2)
	assert_eq(IsoGrid.footprint_center(layer, cell, Vector2i.ONE), layer.map_to_local(cell))
	layer.free()


func test_footprint_center_of_2x2_is_between_cells() -> void:
	var layer := _layer()
	var center := IsoGrid.footprint_center(layer, Vector2i.ZERO, Vector2i(2, 2))
	var origin_center := layer.map_to_local(Vector2i.ZERO)
	assert_near(center.x, origin_center.x)
	assert_near(center.y, origin_center.y + 32.0)
	layer.free()


func test_isometric_cell_offsets_match_tile_size() -> void:
	var layer := _layer()
	var step_x := layer.map_to_local(Vector2i(1, 0)) - layer.map_to_local(Vector2i.ZERO)
	var step_y := layer.map_to_local(Vector2i(0, 1)) - layer.map_to_local(Vector2i.ZERO)
	assert_eq(step_x, Vector2(64, 32))
	assert_eq(step_y, Vector2(-64, 32))
	layer.free()


func test_cell_at_inverts_map_to_local() -> void:
	var layer := _layer()
	var cell := Vector2i(7, 4)
	assert_eq(IsoGrid.cell_at(layer, layer.map_to_local(cell)), cell)
	layer.free()


func test_origin_for_centers_odd_footprints() -> void:
	assert_eq(IsoGrid.origin_for(Vector2i(10, 10), Vector2i(3, 3)), Vector2i(9, 9))
	assert_eq(IsoGrid.origin_for(Vector2i(10, 10), Vector2i.ONE), Vector2i(10, 10))


func test_size_of_accepts_json_arrays_and_vectors() -> void:
	assert_eq(IsoGrid.size_of({"size": [3.0, 3.0]}), Vector2i(3, 3))
	assert_eq(IsoGrid.size_of({"size": Vector2i(2, 2)}), Vector2i(2, 2))
	assert_eq(IsoGrid.size_of({}), Vector2i.ONE)


func test_map_rect_spans_whole_diamond() -> void:
	var layer := _layer()
	var rect := IsoGrid.map_rect(layer, 24)
	assert_near(rect.position.x, -23.0 * 64.0)
	assert_near(rect.end.x, 25.0 * 64.0)
	assert_near(rect.position.y, 0.0)
	assert_near(rect.end.y, 48.0 * 32.0)
	layer.free()
