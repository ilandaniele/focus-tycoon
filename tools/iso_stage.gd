extends SubViewport

const MODEL_DIR := "res://art/kenney/"
const PIXELS_PER_UNIT := IsoGrid.TILE.x * ArtRegistry.ASSET_SCALE / sqrt(2.0)
const CAMERA_PITCH := -30.0
const CAMERA_YAW := 45.0
const CAMERA_DISTANCE := 20.0

var _camera := Camera3D.new()
var _content := Node3D.new()


func _init() -> void:
	transparent_bg = true
	msaa_3d = Viewport.MSAA_4X
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	own_world_3d = true
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.rotation_degrees = Vector3(CAMERA_PITCH, CAMERA_YAW, 0.0)
	add_child(_camera)
	add_child(_content)
	add_child(_build_light())
	add_child(_build_environment())


func frame(canvas: Vector2i, anchor: Vector2) -> void:
	size = canvas
	_camera.size = canvas.y / PIXELS_PER_UNIT
	var basis := _camera.transform.basis
	var screen_offset := anchor - Vector2(canvas) / 2.0
	var shift := (basis.x * -screen_offset.x + basis.y * screen_offset.y) / PIXELS_PER_UNIT
	_camera.position = basis.z * CAMERA_DISTANCE + shift


func clear() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.free()


func add(node: Node3D) -> void:
	_content.add_child(node)


static func load_model(name: String) -> Node3D:
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var path := ProjectSettings.globalize_path(MODEL_DIR + name + ".glb")
	if document.append_from_file(path, state) != OK:
		push_error("cannot load model %s" % path)
		return null
	return document.generate_scene(state) as Node3D


func _build_light() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55.0, 20.0, 0.0)
	light.light_energy = 0.27
	light.shadow_enabled = true
	light.shadow_opacity = 0.45
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	return light


func _build_environment() -> WorldEnvironment:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("FFFFFF")
	environment.ambient_light_energy = 0.21
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world := WorldEnvironment.new()
	world.environment = environment
	return world
