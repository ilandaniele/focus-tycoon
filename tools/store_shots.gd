extends SceneTree

const OUT_DIR := "res://build/store/"
const PHONE_SIZES := {"play": Vector2i(1080, 1920), "appstore": Vector2i(1290, 2796)}
const SCREENS: Array[String] = ["focus", "meditation", "build", "stats"]
const FEATURE_SIZE := Vector2i(1024, 500)
const ICON_SIZE := 512
const ICON_SOURCE := "res://assets/icon/icon.svg"
const TITLE_FONT := "res://assets/fonts/Nunito.ttf"
const SETTLE_SECONDS := 1.5
const PARK_ZOOM := Vector2(1.3, 1.3)
const BODY_SIZE_PER_SCALE := Vector2(64.0, 72.0)
const CLEAR_VIEW_POLL := 0.1
const CLEAR_VIEW_TIMEOUT := 20.0
const BLANK_RETRIES := 120

var _main: Node


func _initialize() -> void:
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	await create_timer(SETTLE_SECONDS).timeout
	_main = current_scene
	_hide_debug_layers()
	for store: String in PHONE_SIZES:
		await _phone_set(store, PHONE_SIZES[store])
	await _feature_graphic()
	_icon()
	quit()


func _hide_debug_layers() -> void:
	_main.get_node("UI/TutorialOverlay").visible = false
	for child in _main.get_children():
		if _is_a(child, "PerfOverlay"):
			child.visible = false


func _phone_set(store: String, size: Vector2i) -> void:
	_resize_window(size)
	_focus_camera()
	await _save_clearest_park("%s_1_park" % store)
	for index in SCREENS.size():
		_main.open_screen(SCREENS[index])
		await create_timer(SETTLE_SECONDS).timeout
		await _save("%s_%d_%s" % [store, index + 2, SCREENS[index]])
	_main.close_screen()


func _resize_window(size: Vector2i) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	root.size = size
	DisplayServer.window_move_to_foreground()


func _save_clearest_park(file_name: String) -> void:
	await create_timer(SETTLE_SECONDS).timeout
	var fewest := -1
	var best: Image
	var waited := 0.0
	while fewest != 0 and waited < CLEAR_VIEW_TIMEOUT:
		var overlaps := _overlap_count()
		if fewest < 0 or overlaps < fewest:
			fewest = overlaps
			best = await _capture(file_name)
		await create_timer(CLEAR_VIEW_POLL).timeout
		waited += CLEAR_VIEW_POLL
	if fewest > 0:
		printerr("%s: %d animal pairs still overlap" % [file_name, fewest])
	_write(best, file_name)


func _overlap_count() -> int:
	var screen := Rect2(Vector2.ZERO, Vector2(root.size))
	var actors := _animal_actors().filter(func(actor: Node2D) -> bool: return screen.has_point(actor.get_global_transform_with_canvas().origin))
	var count := 0
	for first in actors.size():
		for second in range(first + 1, actors.size()):
			if _too_close(actors[first], actors[second]):
				count += 1
	return count


func _too_close(first: Node2D, second: Node2D) -> bool:
	return _body_box(first).intersects(_body_box(second))


func _body_box(actor: Node2D) -> Rect2:
	var size := BODY_SIZE_PER_SCALE * _species_scale(actor)
	return Rect2(actor.position - Vector2(size.x / 2.0, size.y), size)


func _species_scale(actor: Node2D) -> float:
	var config := root.get_node("Config")
	return float(config.species[actor.get("species_id")]["scale"])


func _animal_actors() -> Array:
	var entities := _main.get_node("ParkWorld/Entities")
	return entities.get_children().filter(func(node: Node) -> bool: return _is_a(node, "AnimalActor"))


func _focus_camera() -> void:
	var camera: Camera2D = _main.get_node("ParkWorld/Camera2D")
	var actors := _animal_actors()
	var center := Vector2.ZERO
	for actor: Node2D in actors:
		center += actor.position
	camera.position = center / maxi(actors.size(), 1)
	camera.zoom = PARK_ZOOM


func _feature_graphic() -> void:
	_resize_window(FEATURE_SIZE)
	_main.get_node("UI").visible = false
	var layer := CanvasLayer.new()
	var title := Label.new()
	title.text = "Focus Tycoon"
	title.add_theme_font_override("font", load(TITLE_FONT))
	title.add_theme_font_size_override("font_size", 96)
	title.add_theme_color_override("font_outline_color", Color("2E2420"))
	title.add_theme_constant_override("outline_size", 24)
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title.position.y = 32
	layer.add_child(title)
	_main.add_child(layer)
	_focus_camera()
	await _save_clearest_park("feature_graphic")


func _icon() -> void:
	var image := Image.new()
	image.load_svg_from_string(FileAccess.get_file_as_string(ICON_SOURCE), float(ICON_SIZE) / 512.0)
	image.save_png(OUT_DIR + "icon_512.png")


func _is_a(node: Node, global_name: String) -> bool:
	var script: Script = node.get_script()
	return script != null and script.get_global_name() == global_name


func _save(file_name: String) -> void:
	_write(await _capture(file_name), file_name)


func _capture(file_name: String) -> Image:
	var image := root.get_viewport().get_texture().get_image()
	var retries := 0
	while image.is_invisible() and retries < BLANK_RETRIES:
		await process_frame
		image = root.get_viewport().get_texture().get_image()
		retries += 1
	if image.is_invisible():
		printerr("BLANK %s: rerun with the window visible" % file_name)
	return image


func _write(image: Image, file_name: String) -> void:
	image.save_png(OUT_DIR + file_name + ".png")
	print("%s %dx%d" % [file_name, image.get_width(), image.get_height()])
