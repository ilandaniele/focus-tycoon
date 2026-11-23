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
