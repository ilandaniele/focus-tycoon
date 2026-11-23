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
	root.size = size
	_focus_camera()
	await create_timer(SETTLE_SECONDS).timeout
	_save("%s_1_park" % store)
	for index in SCREENS.size():
		_main.open_screen(SCREENS[index])
		await create_timer(SETTLE_SECONDS).timeout
		_save("%s_%d_%s" % [store, index + 2, SCREENS[index]])
	_main.close_screen()


func _focus_camera() -> void:
	var world := _main.get_node("ParkWorld")
	var camera: Camera2D = world.get_node("Camera2D")
	var actors := world.get_node("Entities").get_children().filter(func(node: Node) -> bool: return _is_a(node, "AnimalActor"))
	var center := Vector2.ZERO
	for actor: Node2D in actors:
		center += actor.position
	camera.position = center / maxi(actors.size(), 1)
	camera.zoom = PARK_ZOOM


func _feature_graphic() -> void:
	root.size = FEATURE_SIZE
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
	await create_timer(SETTLE_SECONDS).timeout
	_save("feature_graphic")


func _icon() -> void:
	var image := Image.new()
	image.load_svg_from_string(FileAccess.get_file_as_string(ICON_SOURCE), float(ICON_SIZE) / 512.0)
	image.save_png(OUT_DIR + "icon_512.png")


func _is_a(node: Node, global_name: String) -> bool:
	var script: Script = node.get_script()
	return script != null and script.get_global_name() == global_name


func _save(file_name: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	if image.is_invisible():
		printerr("BLANK %s: rerun with the window visible" % file_name)
	image.save_png(OUT_DIR + file_name + ".png")
	print("%s %dx%d" % [file_name, image.get_width(), image.get_height()])
