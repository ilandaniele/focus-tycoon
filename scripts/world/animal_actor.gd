class_name AnimalActor
extends Node2D

const WALK_PX_PER_SECOND := 56.0
const REDUCED_MOTION_FACTOR := 0.5
const PAUSE_SECONDS := Vector2(1.5, 4.5)
const BOB_HEIGHT := 3.0
const BOB_SECONDS := 0.35
const SQUASH := Vector2(1.06, 0.94)
const STRETCH := Vector2(0.94, 1.06)
const ANIMATION_FPS := {"idle": 6.0, "walk": 10.0}

var species_id := ""
var enclosure_uid := ""

var _points: Array[Vector2] = []
var _speed := 1.0
var _rest_scale := Vector2.ONE
var _motion_factor := 1.0
var _reduce_motion := false
var _canvas := Vector2.ZERO
var _strips: Dictionary = {}
var _move_tween: Tween
var _bob_tween: Tween
var _frame_tween: Tween

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _shadow: Sprite2D = $Shadow


func setup(new_species_id: String, new_enclosure_uid: String, points: Array[Vector2]) -> void:
	species_id = new_species_id
	enclosure_uid = new_enclosure_uid
	var species: Dictionary = Config.species[species_id]
	_speed = species["speed"]
	_canvas = Vector2(ArtRegistry.ANIMAL_CANVAS)
	_load_strips()
	_sprite.texture = ArtRegistry.get_texture("animals/" + species_id)
	_sprite.centered = false
	_sprite.offset = -ArtRegistry.animal_pivot(_canvas)
	_rest_scale = Vector2.ONE * float(species["scale"])
	_sprite.scale = _rest_scale
	_shadow.texture = ArtRegistry.get_texture("fx/shadow")
	_shadow.scale = _rest_scale
	GameState.settings_changed.connect(_on_setting_changed)
	set_points(points)


func set_points(points: Array[Vector2]) -> void:
	_points = points
	position = _points.pick_random()
	_restart()


func _exit_tree() -> void:
	_kill_tweens()


func _load_strips() -> void:
	for anim: String in ANIMATION_FPS:
		var strip := ArtRegistry.animation(species_id, anim)
		if strip == null:
			_strips.clear()
			return
		_strips[anim] = strip


func _on_setting_changed(key: String) -> void:
	if key == "reduce_motion":
		_restart()


func _restart() -> void:
	_kill_tweens()
	_reduce_motion = GameState.settings.get("reduce_motion", false)
	_motion_factor = REDUCED_MOTION_FACTOR if _reduce_motion else 1.0
	if _strips.is_empty() and not _reduce_motion:
		_start_bob()
	_play("idle")
	_wander_step()


func _kill_tweens() -> void:
	for tween in [_move_tween, _bob_tween, _frame_tween]:
		if tween != null:
			tween.kill()
	_sprite.position = Vector2.ZERO
	_sprite.scale = _rest_scale


func _start_bob() -> void:
	_bob_tween = create_tween().set_loops()
	_bob_tween.tween_property(_sprite, "position:y", -BOB_HEIGHT, BOB_SECONDS).set_trans(Tween.TRANS_SINE)
	_bob_tween.parallel().tween_property(_sprite, "scale", _rest_scale * STRETCH, BOB_SECONDS)
	_bob_tween.tween_property(_sprite, "position:y", 0.0, BOB_SECONDS).set_trans(Tween.TRANS_SINE)
	_bob_tween.parallel().tween_property(_sprite, "scale", _rest_scale * SQUASH, BOB_SECONDS)


func _play(anim: String) -> void:
	if _strips.is_empty():
		return
	if _frame_tween != null:
		_frame_tween.kill()
	var strip: Texture2D = _strips[anim]
	_sprite.frame = 0
	_sprite.texture = strip
	_sprite.hframes = int(strip.get_width() / _canvas.x)
	if anim == "idle" and _reduce_motion:
		return
	var frames := _sprite.hframes
	_frame_tween = create_tween().set_loops()
	_frame_tween.tween_method(_show_frame, 0.0, float(frames), frames / (ANIMATION_FPS[anim] * _motion_factor))


func _show_frame(value: float) -> void:
	_sprite.frame = mini(int(value), _sprite.hframes - 1)


func _wander_step() -> void:
	var target := _next_point()
	var pixels_per_second := WALK_PX_PER_SECOND * _speed * _motion_factor
	_sprite.flip_h = target.x < position.x
	_move_tween = create_tween()
	_move_tween.tween_callback(_play.bind("walk"))
	_move_tween.tween_property(self, "position", target, maxf(position.distance_to(target), 1.0) / pixels_per_second)
	_move_tween.tween_callback(_play.bind("idle"))
	_move_tween.tween_interval(randf_range(PAUSE_SECONDS.x, PAUSE_SECONDS.y) / _motion_factor)
	_move_tween.tween_callback(_wander_step)


func _next_point() -> Vector2:
	if _points.size() < 2:
		return position
	var target: Vector2 = _points.pick_random()
	while target == position:
		target = _points.pick_random()
	return target
