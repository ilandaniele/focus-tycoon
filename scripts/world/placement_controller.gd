class_name PlacementController
extends Node

signal changed(active: bool, valid: bool)

enum Mode { NONE, PLACE, MOVE, ADOPT }

const VALID_TINT := Color(0.45, 1.0, 0.55, 0.7)
const INVALID_TINT := Color(1.0, 0.4, 0.35, 0.7)
const GRID_TINT := Color(1, 1, 1, 0.35)
const MARKER_LIFT := Vector2(0, -56)

var mode := Mode.NONE
var item_id := ""
var uid := ""
var cell := Vector2i.ZERO
var size := Vector2i.ONE
var valid := false
var adopt_targets: Array[String] = []

var _ground: TileMapLayer
var _ghost: Sprite2D
var _marker: Sprite2D
var _overlay: Node2D


func setup(ground: TileMapLayer, ghost: Sprite2D, overlay: Node2D) -> void:
	_ground = ground
	_ghost = ghost
	_overlay = overlay
	_ghost.centered = false
	_marker = Sprite2D.new()
	_marker.position = MARKER_LIFT
	_ghost.add_child(_marker)
	_overlay.draw.connect(_draw_overlay)


func begin_item(new_mode: Mode, new_item_id: String, new_size: Vector2i, new_uid: String, start_cell: Vector2i) -> void:
	mode = new_mode
	item_id = new_item_id
	size = new_size
	uid = new_uid
	adopt_targets.clear()
	var texture := ArtRegistry.get_texture(ArtRegistry.item_key(item_id))
	_ghost.texture = texture
	_ghost.offset = -ArtRegistry.object_pivot(texture, size)
	_show()
	move_to(start_cell)


func begin_adopt(species_id: String, targets: Array[String]) -> void:
	cancel()
	mode = Mode.ADOPT
	item_id = species_id
	adopt_targets = targets
	_show()
	_ghost.visible = false
	_overlay.queue_redraw()
	changed.emit(true, not targets.is_empty())


func move_to(new_cell: Vector2i) -> void:
	cell = new_cell
	valid = _is_valid()
	_ghost.position = IsoGrid.footprint_center(_ground, cell, size)
	_ghost.self_modulate = VALID_TINT if valid else INVALID_TINT
	_marker.texture = ArtRegistry.get_texture("ui/mark_ok" if valid else "ui/mark_bad")
	_overlay.queue_redraw()
	changed.emit(true, valid)


func cancel() -> void:
	if mode == Mode.NONE:
		return
	mode = Mode.NONE
	valid = false
	adopt_targets.clear()
	_ghost.visible = false
	_overlay.visible = false
	changed.emit(false, false)


func is_placing() -> bool:
	return mode == Mode.PLACE or mode == Mode.MOVE


func hits_ghost(world_pos: Vector2) -> bool:
	return is_placing() and IsoGrid.cells_of(cell, size).has(IsoGrid.cell_at(_ground, world_pos))


func _show() -> void:
	_ghost.visible = true
	_overlay.visible = true


func _is_valid() -> bool:
	return GameState.park.can_place(size, cell, uid)


func _draw_overlay() -> void:
	var texture := ArtRegistry.get_texture("terrain/grid_ok")
	var park := GameState.park
	for x in park.map_size:
		for y in park.map_size:
			if park.is_cell_unlocked(Vector2i(x, y)):
				_draw_cell(texture, Vector2i(x, y), GRID_TINT)
	if is_placing():
		for footprint_cell in IsoGrid.cells_of(cell, size):
			_draw_cell(texture, footprint_cell, VALID_TINT if valid else INVALID_TINT)
	for enclosure_uid in adopt_targets:
		var enclosure: Dictionary = park.objects[enclosure_uid]
		for footprint_cell in IsoGrid.cells_of(enclosure["cell"], enclosure["size"]):
			_draw_cell(texture, footprint_cell, VALID_TINT)


func _draw_cell(texture: Texture2D, grid_cell: Vector2i, tint: Color) -> void:
	_overlay.draw_texture(texture, _ground.map_to_local(grid_cell) - texture.get_size() / 2.0, tint)
