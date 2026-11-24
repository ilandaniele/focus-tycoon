class_name IsoGrid
extends RefCounted

const TILE := Vector2i(128, 64)


static func cells_of(cell: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in range(cell.x, cell.x + size.x):
		for y in range(cell.y, cell.y + size.y):
			cells.append(Vector2i(x, y))
	return cells


static func footprint_center(layer: TileMapLayer, cell: Vector2i, size: Vector2i) -> Vector2:
	return (layer.map_to_local(cell) + layer.map_to_local(cell + size - Vector2i.ONE)) / 2.0


static func cell_at(layer: TileMapLayer, world_pos: Vector2) -> Vector2i:
	return layer.local_to_map(layer.to_local(world_pos))


static func origin_for(center_cell: Vector2i, size: Vector2i) -> Vector2i:
	return center_cell - (size - Vector2i.ONE) / 2


static func map_rect(layer: TileMapLayer, map_size: int) -> Rect2:
	var last := Vector2i(map_size - 1, map_size - 1)
	var top_left := Vector2(layer.map_to_local(Vector2i(0, last.y)).x, layer.map_to_local(Vector2i.ZERO).y) - Vector2(TILE) / 2.0
	var bottom_right := Vector2(layer.map_to_local(Vector2i(last.x, 0)).x, layer.map_to_local(last).y) + Vector2(TILE) / 2.0
	return Rect2(top_left, bottom_right - top_left)


static func size_of(item: Dictionary) -> Vector2i:
	var size: Variant = item.get("size", Vector2i.ONE)
	if size is Vector2i:
		return size
	return Vector2i(int(size[0]), int(size[1]))
