extends TestCase

const OBJECT_SIZES := {1: Vector2i(128, 160), 2: Vector2i(256, 256), 3: Vector2i(384, 320), 4: Vector2i(512, 384)}


func _items() -> Array:
	return Config.catalog.values()


func test_every_catalog_item_has_texture_with_canvas_size() -> void:
	for item: Dictionary in _items():
		var texture := ArtRegistry.get_texture(ArtRegistry.item_key(item["id"]))
		assert_true(texture != null, "texture for %s" % item["id"])
		if item["category"] == "path":
			assert_eq(texture.get_size(), Vector2(128, 64), item["id"])
		else:
			var side := IsoGrid.size_of(item).x
			assert_eq(texture.get_size(), Vector2(OBJECT_SIZES[side]), item["id"])


func test_every_species_has_texture_with_canvas_size() -> void:
	for species_id: String in Config.species:
		var texture := ArtRegistry.get_texture("animals/" + species_id)
		assert_true(texture != null, "texture for %s" % species_id)
		var expected := Vector2(160, 128) if species_id == "elephant" else Vector2(96, 96)
		assert_eq(texture.get_size(), expected, species_id)


func test_terrain_and_marker_keys_exist() -> void:
	for key in ["terrain/grass", "terrain/locked", "terrain/grid_ok"]:
		assert_eq(ArtRegistry.get_texture(key).get_size(), Vector2(128, 64), key)
	for key in ["ui/mark_ok", "ui/mark_bad", "fx/shadow"]:
		assert_true(ArtRegistry.get_texture(key) != null, key)


func test_textures_are_cached() -> void:
	assert_true(ArtRegistry.get_texture("terrain/grass") == ArtRegistry.get_texture("terrain/grass"))


func test_unknown_key_is_null_without_crash() -> void:
	assert_true(ArtRegistry.get_texture("nothing/here") == null)


func test_tiles_are_not_blank() -> void:
	var image := ArtRegistry.get_texture("terrain/grass").get_image()
	assert_true(image.get_pixel(image.get_width() / 2, image.get_height() / 2).a > 0.99)
	assert_true(image.get_pixel(0, 0).a < 0.01)


func test_rendered_assets_keep_extra_pixels_at_logical_size() -> void:
	var texture := ArtRegistry.get_texture("objects/tree_oak")
	assert_eq(texture.get_size(), Vector2(128, 160))
	assert_eq(texture.get_image().get_size(), Vector2i(128, 160) * ArtRegistry.ASSET_SCALE)


func test_object_pivot_is_base_center() -> void:
	var tree := ArtRegistry.get_texture("objects/tree_oak")
	assert_eq(ArtRegistry.object_pivot(tree, Vector2i.ONE), Vector2(64, 128))
	var enclosure := ArtRegistry.get_texture("objects/enclosure_meadow")
	assert_eq(ArtRegistry.object_pivot(enclosure, Vector2i(3, 3)), Vector2(192, 224))


func test_tileset_has_source_per_tile_key() -> void:
	var tile_set := ArtRegistry.build_tileset()
	var keys := ArtRegistry.tile_keys()
	assert_eq(tile_set.get_source_count(), keys.size())
	assert_eq(tile_set.tile_shape, TileSet.TILE_SHAPE_ISOMETRIC)
	assert_eq(tile_set.tile_size, Vector2i(128, 64))
	assert_true(keys.has("paths/path_dirt"))


func test_tileset_atlas_holds_exactly_one_tile() -> void:
	var tile_set := ArtRegistry.build_tileset()
	for i in tile_set.get_source_count():
		var source := tile_set.get_source(i) as TileSetAtlasSource
		assert_eq(source.texture.get_image().get_size(), IsoGrid.TILE)
