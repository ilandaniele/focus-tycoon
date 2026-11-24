class_name PlacedObject
extends Sprite2D

var uid := ""
var size := Vector2i.ONE


func setup(layer: TileMapLayer, entry: Dictionary) -> void:
	uid = entry["uid"]
	size = entry["size"]
	texture = ArtRegistry.get_texture(ArtRegistry.item_key(entry["item_id"]))
	centered = false
	offset = -ArtRegistry.object_pivot(texture, size)
	place(layer, entry["cell"])


func place(layer: TileMapLayer, cell: Vector2i) -> void:
	position = IsoGrid.footprint_center(layer, cell, size)
