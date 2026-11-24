class_name VisitorRoutes
extends RefCounted

const STEPS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


static func path_cells(park: ParkModel, catalog: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for entry: Dictionary in park.objects.values():
		if _category(entry, catalog) == "path":
			cells.append(entry["cell"])
	return cells


static func route_cells(park: ParkModel, catalog: Dictionary) -> Array[Vector2i]:
	var cells := path_cells(park, catalog)
	cells.append_array(park.entrance_cells())
	return cells


static func spawn_cells(park: ParkModel, catalog: Dictionary) -> Array[Vector2i]:
	var cells := path_cells(park, catalog)
	var entrance := park.entrance_cells()
	if entrance.is_empty() or not cells.has(park.gate_cell()):
		return cells
	return [entrance.back()]


static func neighbors(cell: Vector2i, cells: Array[Vector2i]) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for step in STEPS:
		if cells.has(cell + step):
			found.append(cell + step)
	return found


static func next_cell(current: Vector2i, previous: Vector2i, cells: Array[Vector2i], rng: RandomNumberGenerator) -> Vector2i:
	var options := neighbors(current, cells)
	if options.is_empty():
		return current
	var forward := options.filter(func(cell: Vector2i) -> bool: return cell != previous)
	var pool: Array = forward if not forward.is_empty() else options
	return pool[rng.randi_range(0, pool.size() - 1)]


static func viewing_cells(park: ParkModel, catalog: Dictionary) -> Array[Vector2i]:
	var views: Array[Vector2i] = []
	for cell in path_cells(park, catalog):
		for step in STEPS:
			var uid := park.object_at(cell + step)
			if uid != "" and _is_attraction(park, park.objects[uid], catalog):
				views.append(cell)
				break
	return views


static func visitor_count(park: ParkModel, catalog: Dictionary, tuning: Dictionary) -> int:
	if path_cells(park, catalog).is_empty():
		return 0
	var attractions := park.objects.values().filter(func(entry: Dictionary) -> bool: return _is_attraction(park, entry, catalog)).size()
	return mini(int(tuning["max"]), int(tuning["base"]) + attractions * int(tuning["per_attraction"]))


static func _is_attraction(park: ParkModel, entry: Dictionary, catalog: Dictionary) -> bool:
	match _category(entry, catalog):
		"building":
			return true
		"enclosure":
			return not park.animals_in(entry["uid"]).is_empty()
	return false


static func _category(entry: Dictionary, catalog: Dictionary) -> String:
	return catalog[entry["item_id"]]["category"]
