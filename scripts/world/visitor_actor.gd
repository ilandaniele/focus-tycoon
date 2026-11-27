class_name VisitorActor
extends AnimalActor

const SHADOW_SCALE := Vector2(0.45, 0.45)

var _ground: TileMapLayer
var _cells: Array[Vector2i] = []
var _views: Array[Vector2i] = []
var _cell := Vector2i.ZERO
var _previous := Vector2i.ZERO
var _rng := RandomNumberGenerator.new()


func setup_visitor(variant: String, ground: TileMapLayer, cells: Array[Vector2i], views: Array[Vector2i], spawns: Array[Vector2i]) -> void:
	_ground = ground
	_rng.randomize()
	_begin("visitors/" + variant, float(_tuning()["walk_px_per_second"]), 1.0)
	_shadow.scale = SHADOW_SCALE
	_cells = cells
	_views = views
	_enter_at(spawns.pick_random())


func set_routes(cells: Array[Vector2i], views: Array[Vector2i], spawns: Array[Vector2i]) -> void:
	_cells = cells
	_views = views
	if not _cells.has(_cell):
		_enter_at(spawns.pick_random())


func _enter_at(cell: Vector2i) -> void:
	_cell = cell
	_previous = cell
	position = _ground.map_to_local(cell)
	_restart()


func _next_point() -> Vector2:
	var next := VisitorRoutes.next_cell(_cell, _previous, _cells, _rng)
	_previous = _cell
	_cell = next
	return _ground.map_to_local(next)


func _pause_seconds() -> float:
	var tuning := _tuning()
	var stuck := _cell == _previous
	if stuck or (_views.has(_cell) and _rng.randf() < float(tuning["look_chance"])):
		return _rng.randf_range(float(tuning["look_seconds"][0]), float(tuning["look_seconds"][1]))
	return 0.0


func _tuning() -> Dictionary:
	return Config.economy["visitors"]


func _eases_steps() -> bool:
	return false
