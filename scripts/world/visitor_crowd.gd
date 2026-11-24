class_name VisitorCrowd
extends RefCounted

const VISITOR_SCENE := preload("res://scenes/world/visitor_actor.tscn")

var _visitors: Array[VisitorActor] = []


func forget() -> void:
	_visitors.clear()


func refresh(entities: Node2D, ground: TileMapLayer, park: ParkModel) -> void:
	var tuning: Dictionary = Config.economy["visitors"]
	var cells := VisitorRoutes.path_cells(park, Config.catalog)
	var views := VisitorRoutes.viewing_cells(park, Config.catalog)
	var count := VisitorRoutes.visitor_count(park, Config.catalog, tuning)
	while _visitors.size() > count:
		_visitors.pop_back().queue_free()
	for visitor in _visitors:
		visitor.set_routes(cells, views)
	var variants: Array = tuning["variants"]
	while _visitors.size() < count:
		var visitor: VisitorActor = VISITOR_SCENE.instantiate()
		entities.add_child(visitor)
		visitor.setup_visitor(variants.pick_random(), ground, cells, views)
		_visitors.append(visitor)
