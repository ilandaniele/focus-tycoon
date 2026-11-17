extends SceneTree

const IsoStage := preload("res://tools/iso_stage.gd")
const ModelSpecs := preload("res://tools/model_specs.gd")
const ScenePieces := preload("res://tools/scene_pieces.gd")
const TARGET_DIR := "res://assets/"
const SETTLE_FRAMES := 3

var _stage: IsoStage


func _initialize() -> void:
	_stage = IsoStage.new()
	root.add_child(_stage)
	_render_all.call_deferred()


func _render_all() -> void:
	var only := OS.get_cmdline_user_args()
	var rendered := 0
	for key: String in ModelSpecs.TILES:
		if _wanted(key, only):
			await _render_tile(key, ModelSpecs.TILES[key])
			rendered += 1
	for key: String in ModelSpecs.OBJECTS:
		if _wanted(key, only):
			await _render_object(key, ModelSpecs.OBJECTS[key])
			rendered += 1
	for species_id: String in ModelSpecs.ANIMALS:
		if _wanted("animals/" + species_id, only):
			await _render_animal(species_id, ModelSpecs.ANIMALS[species_id])
			rendered += 1
	print("%d keys rendered" % rendered)
	quit()


func _wanted(key: String, only: PackedStringArray) -> bool:
	return only.is_empty() or key in only


func _render_tile(key: String, parts: Array) -> void:
	_stage.clear()
	ScenePieces.build(_stage, parts)
	var canvas := IsoGrid.TILE * ArtRegistry.ASSET_SCALE
	_stage.frame(canvas, Vector2(canvas) / 2.0)
	var image := await _capture()
	_mask_diamond(image)
	_save(image, key)


func _render_object(key: String, spec: Dictionary) -> void:
	var size := Vector2i(spec["size"][0], spec["size"][1])
	var canvas := (ArtRegistry.OBJECT_CANVAS[size] as Vector2i) * ArtRegistry.ASSET_SCALE
	_stage.clear()
	ScenePieces.build(_stage, spec["parts"])
	_stage.frame(canvas, Vector2(canvas.x / 2.0, canvas.y - (size.x + size.y) * 16.0 * ArtRegistry.ASSET_SCALE))
	_save(await _capture(), key)


func _render_animal(species_id: String, spec: Dictionary) -> void:
	var canvas := ArtRegistry.ANIMAL_CANVAS * ArtRegistry.ASSET_SCALE
	var anchor := Vector2(canvas.x / 2.0, canvas.y - ArtRegistry.FOOT_MARGIN * ArtRegistry.ASSET_SCALE)
	_stage.clear()
	var model := IsoStage.load_model("pets/animal-" + spec["model"])
	model.rotation_degrees.y = ModelSpecs.ANIMAL_FACING
	model.scale = Vector3.ONE * float(spec.get("scale", ModelSpecs.ANIMAL_SCALE))
	_stage.add(model)
	_stage.frame(canvas, anchor)
	var player: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	for anim: String in ModelSpecs.ANIMAL_FRAMES:
		var count: int = ModelSpecs.ANIMAL_FRAMES[anim]
		var strip := Image.create_empty(canvas.x * count, canvas.y, false, Image.FORMAT_RGBA8)
		player.play(anim)
		var length := player.current_animation_length
		for index in count:
			player.seek(length * index / count, true)
			var frame := await _capture()
			strip.blit_rect(frame, Rect2i(Vector2i.ZERO, canvas), Vector2i(canvas.x * index, 0))
			if anim == "idle" and index == 0:
				_save(frame, "animals/" + species_id)
		_save(strip, "animals/%s_%s" % [species_id, anim])


func _capture() -> Image:
	for i in SETTLE_FRAMES:
		await process_frame
	var image := _stage.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	return image


func _mask_diamond(image: Image) -> void:
	var half := Vector2(image.get_size()) / 2.0
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			var distance := absf(x + 0.5 - half.x) / half.x + absf(y + 0.5 - half.y) / half.y
			color.a = 1.0 if distance <= 1.0 + 1.0 / half.y else 0.0
			image.set_pixel(x, y, color)


func _save(image: Image, key: String) -> void:
	var path := TARGET_DIR + key + ".png"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	image.save_png(path)
	print("%s (%dx%d)" % [path, image.get_width(), image.get_height()])
