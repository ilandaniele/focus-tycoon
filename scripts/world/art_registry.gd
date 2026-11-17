class_name ArtRegistry
extends RefCounted

const ASSET_DIR := "res://assets/"
const ASSET_SCALE := 2
const OBJECT_CANVAS := {
	Vector2i(1, 1): Vector2i(128, 160),
	Vector2i(2, 2): Vector2i(256, 256),
	Vector2i(3, 3): Vector2i(384, 320),
	Vector2i(4, 4): Vector2i(512, 384),
}
const ANIMAL_CANVAS := Vector2i(96, 96)
const ANIMAL_CANVAS_BY_SPECIES := {"elephant": Vector2i(160, 128)}
const FOOT_MARGIN := 12.0
const DEFAULT_ANIMAL_COLOR := Color("C9A27E")
const BASE_TILE_KEYS: Array[String] = ["terrain/grass", "terrain/locked"]

static var _cache: Dictionary = {}


static func get_texture(key: String) -> Texture2D:
	if not _cache.has(key):
		var texture := _load_asset(key)
		if texture == null:
			texture = _generate(key)
		if texture == null:
			push_error("no art for key: %s" % key)
			return null
		_cache[key] = texture
	return _cache[key]


static func item_key(item_id: String) -> String:
	return ("paths/" if is_path(item_id) else "objects/") + item_id


static func is_path(item_id: String) -> bool:
	return Config.item(item_id).get("category", "") == "path"


static func canvas_size(size: Vector2i) -> Vector2i:
	if OBJECT_CANVAS.has(size):
		return OBJECT_CANVAS[size]
	var span := size.x + size.y
	return Vector2i(span * 64, span * 32 + 128)


static func animal_canvas(species_id: String) -> Vector2i:
	return ANIMAL_CANVAS_BY_SPECIES.get(species_id, ANIMAL_CANVAS)


static func object_pivot(texture: Texture2D, size: Vector2i) -> Vector2:
	return Vector2(texture.get_width() / 2.0, texture.get_height() - (size.x + size.y) * 16.0)


static func animal_pivot(texture: Texture2D) -> Vector2:
	return Vector2(texture.get_width() / 2.0, texture.get_height() - FOOT_MARGIN)


static func tile_keys() -> Array[String]:
	var path_ids: Array[String] = []
	for item: Dictionary in Config.items_in("path"):
		path_ids.append(item["id"])
	path_ids.sort()
	var keys := BASE_TILE_KEYS.duplicate()
	for item_id in path_ids:
		keys.append("paths/" + item_id)
	return keys


static func build_tileset() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
	tile_set.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
	tile_set.tile_size = IsoGrid.TILE
	var keys := tile_keys()
	for i in keys.size():
		var source := TileSetAtlasSource.new()
		source.texture = _at_logical_size(get_texture(keys[i]))
		source.texture_region_size = IsoGrid.TILE
		source.create_tile(Vector2i.ZERO)
		tile_set.add_source(source, i)
	return tile_set


static func _at_logical_size(texture: Texture2D) -> Texture2D:
	var image := texture.get_image()
	if image.get_size() == Vector2i(texture.get_size()):
		return texture
	image.resize(texture.get_width(), texture.get_height(), Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)


static func _load_asset(key: String) -> Texture2D:
	var path := "%s%s.png" % [ASSET_DIR, key]
	if not ResourceLoader.exists(path):
		return null
	var image := (load(path) as Texture2D).get_image()
	var texture := ImageTexture.create_from_image(image)
	texture.set_size_override(image.get_size() / ASSET_SCALE)
	return texture


static func _generate(key: String) -> Texture2D:
	var parts := key.split("/", true, 1)
	var id := parts[1] if parts.size() > 1 else ""
	var image: Image
	match parts[0]:
		"terrain":
			image = PlaceholderArt.terrain(id)
		"paths":
			image = PlaceholderArt.path(id)
		"objects":
			image = _object_image(id)
		"animals":
			image = _animal_image(id)
		"ui":
			image = PlaceholderArt.mark(id == "mark_ok")
		"fx":
			image = PlaceholderArt.shadow()
	return ImageTexture.create_from_image(image) if image != null else null


static func _object_image(item_id: String) -> Image:
	var item := Config.item(item_id)
	var size := IsoGrid.size_of(item)
	return PlaceholderArt.object(item_id, item, size, canvas_size(size))


static func _animal_image(species_id: String) -> Image:
	var species: Dictionary = Config.species.get(species_id, {})
	var color := Color.html(species["color"]) if species.has("color") else DEFAULT_ANIMAL_COLOR
	return PlaceholderAnimals.draw(species_id, color, animal_canvas(species_id), FOOT_MARGIN)
