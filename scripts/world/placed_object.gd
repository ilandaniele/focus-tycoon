class_name PlacedObject
extends Sprite2D

const ENCLOSURE_Z := -1

var uid := ""
var size := Vector2i.ONE


func setup(layer: TileMapLayer, entry: Dictionary) -> void:
	uid = entry["uid"]
	size = entry["size"]
	var item_id: String = entry["item_id"]
	texture = ArtRegistry.get_texture(ArtRegistry.item_key(item_id))
	centered = false
	offset = -ArtRegistry.object_pivot(texture, size)
	if Config.item(item_id).get("category", "") == "enclosure":
		z_index = ENCLOSURE_Z
	place(layer, entry["cell"])


func place(layer: TileMapLayer, cell: Vector2i) -> void:
	position = IsoGrid.footprint_center(layer, cell, size)
