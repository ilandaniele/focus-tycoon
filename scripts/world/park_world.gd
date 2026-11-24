class_name ParkWorld
extends Node2D

signal object_tapped(uid: String)
signal placement_changed(active: bool, valid: bool)
signal adopt_resolved(result: Dictionary)

const ANIMAL_SCENE := preload("res://scenes/world/animal_actor.tscn")

var _tile_source: Dictionary = {}
var _objects: Dictionary = {}
var _actors: Dictionary = {}
var _crowd := VisitorCrowd.new()

@onready var _island_edge: IslandEdge = $IslandEdge
@onready var _ground: TileMapLayer = $Ground
@onready var _paths: TileMapLayer = $Paths
@onready var _grid_overlay: Node2D = $GridOverlay
@onready var _entities: Node2D = $Entities
@onready var _wild_props: WildProps = $Entities/WildProps
@onready var _ghost: Sprite2D = $Ghost
@onready var _placement: PlacementController = $PlacementController
@onready var _camera: CameraController = $Camera2D


func _ready() -> void:
	var tile_set := ArtRegistry.build_tileset()
	_ground.tile_set = tile_set
	_paths.tile_set = tile_set
	var keys := ArtRegistry.tile_keys()
	for i in keys.size():
		_tile_source[keys[i]] = i
	_placement.setup(_ground, _ghost, _grid_overlay)
	_placement.changed.connect(placement_changed.emit)
	_camera.tapped.connect(_on_tapped)
	_camera.dragged.connect(_on_dragged)
	_camera.drag_filter = _placement.hits_ghost
	GameState.state_loaded.connect(rebuild)
	ParkService.object_placed.connect(_on_object_placed)
	ParkService.object_moved.connect(_on_object_moved)
	ParkService.object_removed.connect(_on_object_removed)
	ParkService.animal_adopted.connect(_on_animal_adopted)
	ParkService.park_expanded.connect(_on_park_expanded)
	rebuild()


func set_active(active: bool) -> void:
	if not active:
		cancel_placement()
	visible = active
	process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED


func begin_placement(item_id: String) -> void:
	var size := IsoGrid.size_of(Config.item(item_id))
	var start := GameState.park.nearest_free_cell(size, IsoGrid.origin_for(IsoGrid.cell_at(_ground, _camera.position), size))
	_placement.begin_item(PlacementController.Mode.PLACE, item_id, size, "", start)


func begin_move(uid: String) -> void:
	var entry: Dictionary = GameState.park.objects[uid]
	_placement.begin_item(PlacementController.Mode.MOVE, entry["item_id"], entry["size"], uid, entry["cell"])


func begin_adopt_target(species_id: String) -> void:
	var targets: Array[String] = []
	targets.assign(ParkService.enclosures_for(species_id))
	_placement.begin_adopt(species_id, targets)


func confirm_placement() -> Dictionary:
	if _placement.mode == PlacementController.Mode.ADOPT and not _placement.adopt_targets.is_empty():
		return _adopt_into(_placement.adopt_targets[0])
	if not _placement.is_placing():
		return {"ok": false, "error": "invalid_cell"}
	var result := _commit_placement()
	if result["ok"]:
		_placement.cancel()
	return result


func cancel_placement() -> void:
	_placement.cancel()


func focus_cell(cell: Vector2i) -> void:
	_camera.focus_to(_ground.map_to_local(cell))


func rebuild() -> void:
	var park := GameState.park
	for node: Node in _entities.get_children():
		if node != _wild_props:
			node.queue_free()
	_objects.clear()
	_actors.clear()
	_crowd.forget()
	_paint_ground()
	_refresh_paths()
	for uid: String in park.objects:
		if not ArtRegistry.is_path(park.objects[uid]["item_id"]):
			_spawn_object(uid)
	for uid: String in park.animals:
		_spawn_animal(uid)
	_refresh_visitors()
	_camera.bounds = IsoGrid.map_rect(_ground, park.map_size)
	_camera.position = _ground.map_to_local(Vector2i(park.map_size, park.map_size) / 2)


func _commit_placement() -> Dictionary:
	if _placement.mode == PlacementController.Mode.MOVE:
		var moved := ParkService.move_object(_placement.uid, _placement.cell)
		return {"ok": moved, "error": "" if moved else "invalid_cell", "uid": _placement.uid}
	return ParkService.buy_and_place(_placement.item_id, _placement.cell)


func _paint_ground() -> void:
	var park := GameState.park
	for x in park.map_size:
		for y in park.map_size:
			var cell := Vector2i(x, y)
			var key := Scenery.ground_key(cell, park.is_cell_unlocked(cell))
			_ground.set_cell(cell, _tile_source[key], Vector2i.ZERO)
	_wild_props.paint(_ground, park)
	_island_edge.setup(_ground, park.map_size)


func _refresh_paths() -> void:
	_paths.clear()
	for entry: Dictionary in GameState.park.objects.values():
		var item_id: String = entry["item_id"]
		if ArtRegistry.is_path(item_id):
			_paths.set_cell(entry["cell"], _tile_source["paths/" + item_id], Vector2i.ZERO)


func _spawn_object(uid: String) -> void:
	var node := PlacedObject.new()
	_entities.add_child(node)
	node.setup(_ground, GameState.park.objects[uid])
	_objects[uid] = node


func _spawn_animal(uid: String) -> void:
	var entry: Dictionary = GameState.park.animals[uid]
	var actor: AnimalActor = ANIMAL_SCENE.instantiate()
	_entities.add_child(actor)
	actor.setup(entry["species_id"], entry["enclosure_uid"], _enclosure_points(entry["enclosure_uid"]))
	_actors[uid] = actor


func _refresh_visitors() -> void:
	_crowd.refresh(_entities, _ground, GameState.park)


func _enclosure_points(enclosure_uid: String) -> Array[Vector2]:
	var enclosure: Dictionary = GameState.park.objects[enclosure_uid]
	return IsoGrid.cell_centers(_ground, enclosure["cell"], enclosure["size"])


func _on_object_placed(uid: String) -> void:
	_refresh_visitors()
	var entry: Dictionary = GameState.park.objects[uid]
	if ArtRegistry.is_path(entry["item_id"]):
		_refresh_paths()
		WorldFx.celebrate(_entities, _ground.map_to_local(entry["cell"]))
		return
	_spawn_object(uid)
	WorldFx.celebrate(_entities, _objects[uid].position, _objects[uid])


func _on_animal_adopted(uid: String) -> void:
	_refresh_visitors()
	_spawn_animal(uid)
	WorldFx.celebrate(_entities, _actors[uid].position, _actors[uid])


func _on_object_moved(uid: String) -> void:
	_refresh_visitors()
	if not _objects.has(uid):
		_refresh_paths()
		return
	_objects[uid].place(_ground, GameState.park.objects[uid]["cell"])
	for actor: AnimalActor in _actors.values():
		if actor.enclosure_uid == uid:
			actor.set_points(_enclosure_points(uid))


func _on_object_removed(uid: String) -> void:
	_refresh_visitors()
	if _objects.has(uid):
		_objects[uid].queue_free()
		_objects.erase(uid)
	else:
		_refresh_paths()


func _on_park_expanded(_size: int) -> void:
	_paint_ground()
	_grid_overlay.queue_redraw()


func _on_tapped(world_pos: Vector2) -> void:
	var cell := IsoGrid.cell_at(_ground, world_pos)
	match _placement.mode:
		PlacementController.Mode.NONE:
			_tap_object(cell)
		PlacementController.Mode.ADOPT:
			_tap_adopt_target(cell)
		_:
			_move_ghost_to(cell)


func _on_dragged(world_pos: Vector2) -> void:
	_move_ghost_to(IsoGrid.cell_at(_ground, world_pos))


func _move_ghost_to(cell: Vector2i) -> void:
	_placement.move_to(IsoGrid.origin_for(cell, _placement.size))


func _tap_object(cell: Vector2i) -> void:
	var uid := GameState.park.object_at(cell)
	if uid != "":
		object_tapped.emit(uid)


func _tap_adopt_target(cell: Vector2i) -> void:
	var uid := GameState.park.object_at(cell)
	if _placement.adopt_targets.has(uid):
		adopt_resolved.emit(_adopt_into(uid))


func _adopt_into(enclosure_uid: String) -> Dictionary:
	var result := ParkService.adopt(_placement.item_id, enclosure_uid)
	if result["ok"]:
		_placement.cancel()
	return result
