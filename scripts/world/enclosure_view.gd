class_name EnclosureView
extends Node2D

const FLOOR_Z := -2
const BACK_FENCE_Z := -1
const FRONT_FENCE_Z := 0
const EDGE_X := Vector2(32, 16)
const EDGE_Y := Vector2(-32, 16)

var uid := ""
var size := Vector2i.ONE
var _item_id := ""


static func decor_cells(item_id: String, size: Vector2i) -> Array[Vector2i]:
	var corners: Array[Vector2i] = [Vector2i.ZERO, Vector2i(size.x - 1, 0), Vector2i(0, size.y - 1), size - Vector2i.ONE]
	return corners.slice(0, _decor(item_id).size())


static func _decor(item_id: String) -> Array:
	return Config.item(item_id).get("decor", [])


func setup(layer: TileMapLayer, entry: Dictionary) -> void:
	uid = entry["uid"]
	_item_id = entry["item_id"]
	size = entry["size"]
	y_sort_enabled = true
	place(layer, entry["cell"])


func place(layer: TileMapLayer, cell: Vector2i) -> void:
	position = IsoGrid.footprint_center(layer, cell, size)
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var cells := GameState.park.cells_of(uid)
	for covered in cells:
		var at := layer.map_to_local(covered) - position
		_add_piece("objects/%s_floor" % _item_id, at, FLOOR_Z)
		_add_fences(covered, cells, at)
	var decor := _decor(_item_id)
	var spots := decor_cells(_item_id, size)
	for index in spots.size():
		_add_piece(ArtRegistry.item_key(decor[index]), layer.map_to_local(cell + spots[index]) - position, 0)


func _add_fences(covered: Vector2i, cells: Array[Vector2i], at: Vector2) -> void:
	var fence_x := "objects/%s_fence_x" % _item_id
	var fence_y := "objects/%s_fence_y" % _item_id
	if not cells.has(covered + Vector2i.UP):
		_add_piece(fence_x, at - EDGE_Y, BACK_FENCE_Z)
	if not cells.has(covered + Vector2i.LEFT):
		_add_piece(fence_y, at - EDGE_X, BACK_FENCE_Z)
	if not cells.has(covered + Vector2i.DOWN):
		_add_piece(fence_x, at + EDGE_Y, FRONT_FENCE_Z)
	if not cells.has(covered + Vector2i.RIGHT):
		_add_piece(fence_y, at + EDGE_X, FRONT_FENCE_Z)


func _add_piece(key: String, at: Vector2, z: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = ArtRegistry.get_texture(key)
	sprite.centered = false
	sprite.offset = -ArtRegistry.object_pivot(sprite.texture, Vector2i.ONE)
	sprite.position = at
	sprite.z_index = z
	add_child(sprite)
