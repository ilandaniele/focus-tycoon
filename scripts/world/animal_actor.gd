class_name AnimalActor
extends Node2D

const WALK_PX_PER_SECOND := 56.0
const REDUCED_MOTION_FACTOR := 0.5
const PAUSE_SECONDS := Vector2(1.5, 4.5)
const BOB_HEIGHT := 3.0
const BOB_SECONDS := 0.35
const SQUASH := Vector2(1.06, 0.94)
const STRETCH := Vector2(0.94, 1.06)

var species_id := ""
var enclosure_uid := ""

var _points: Array[Vector2] = []
var _speed := 1.0
var _rest_scale := Vector2.ONE
var _motion_factor := 1.0
var _move_tween: Tween
var _bob_tween: Tween

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _shadow: Sprite2D = $Shadow


func setup(new_species_id: String, new_enclosure_uid: String, points: Array[Vector2]) -> void:
	species_id = new_species_id
	enclosure_uid = new_enclosure_uid
	var species: Dictionary = Config.species[species_id]
	_speed = species["speed"]
	_sprite.texture = ArtRegistry.get_texture("animals/" + species_id)
	_sprite.centered = false
	_sprite.offset = -ArtRegistry.animal_pivot(_sprite.texture)
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


func _on_setting_changed(key: String) -> void:
	if key == "reduce_motion":
		_restart()


func _restart() -> void:
	_kill_tweens()
	var reduce_motion: bool = GameState.settings.get("reduce_motion", false)
	_motion_factor = REDUCED_MOTION_FACTOR if reduce_motion else 1.0
	if not reduce_motion:
		_start_bob()
	_wander_step()


func _kill_tweens() -> void:
	for tween in [_move_tween, _bob_tween]:
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


func _wander_step() -> void:
	var target := _next_point()
	var pixels_per_second := WALK_PX_PER_SECOND * _speed * _motion_factor
	_sprite.flip_h = target.x < position.x
	_move_tween = create_tween()
	_move_tween.tween_property(self, "position", target, maxf(position.distance_to(target), 1.0) / pixels_per_second)
	_move_tween.tween_interval(randf_range(PAUSE_SECONDS.x, PAUSE_SECONDS.y) / _motion_factor)
	_move_tween.tween_callback(_wander_step)


func _next_point() -> Vector2:
	if _points.size() < 2:
		return position
	var target: Vector2 = _points.pick_random()
	while target == position:
		target = _points.pick_random()
	return target
