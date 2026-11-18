class_name WildProps
extends Node2D


func paint(layer: TileMapLayer, park: ParkModel) -> void:
	for child: Node in get_children():
		child.queue_free()
	for x in park.map_size:
		for y in park.map_size:
			var cell := Vector2i(x, y)
			if park.is_cell_unlocked(cell):
				continue
			var key := Scenery.prop_key(cell, _borders_open_ground(park, cell))
			if key != "":
				_spawn(layer, cell, key)


func _spawn(layer: TileMapLayer, cell: Vector2i, key: String) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = ArtRegistry.get_texture(key)
	sprite.centered = false
	sprite.offset = -ArtRegistry.object_pivot(sprite.texture, Vector2i.ONE)
	sprite.position = IsoGrid.footprint_center(layer, cell, Vector2i.ONE)
	sprite.modulate = Scenery.PROP_TINT
	add_child(sprite)


func _borders_open_ground(park: ParkModel, cell: Vector2i) -> bool:
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if park.is_cell_unlocked(cell + Vector2i(dx, dy)):
				return true
	return false
