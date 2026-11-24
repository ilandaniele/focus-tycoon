class_name ParkModel
extends RefCounted

const STEPS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var map_size: int
var unlocked_size: int
var objects: Dictionary = {}
var animals: Dictionary = {}
var _occupancy: Dictionary = {}


func _init(p_map_size: int, p_unlocked_size: int) -> void:
	map_size = p_map_size
	unlocked_size = p_unlocked_size


func is_cell_unlocked(cell: Vector2i) -> bool:
	var margin := _margin()
	return cell.x >= margin and cell.y >= margin and cell.x < margin + unlocked_size and cell.y < margin + unlocked_size


@warning_ignore("integer_division")
func entrance_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(_margin() + unlocked_size, map_size):
		cells.append(Vector2i(map_size / 2, y))
	return cells


@warning_ignore("integer_division")
func gate_cell() -> Vector2i:
	return Vector2i(map_size / 2, _margin() + unlocked_size - 1)


@warning_ignore("integer_division")
func grow(new_size: int) -> void:
	if new_size <= map_size:
		return
	var offset := Vector2i.ONE * ((new_size - map_size) / 2)
	map_size = new_size
	_occupancy.clear()
	for entry: Dictionary in objects.values():
		entry["cell"] += offset
		_occupy(entry["uid"])


func can_place(size: Vector2i, cell: Vector2i, ignore_uid: String = "") -> bool:
	return _can_cover(_footprint(size, cell), ignore_uid)


func can_move(uid: String, cell: Vector2i) -> bool:
	return objects.has(uid) and _can_cover(_cells(objects[uid], cell), uid)


func cells_of(uid: String) -> Array[Vector2i]:
	return _cells(objects[uid], objects[uid]["cell"])


func shape_candidates(uid: String) -> Array[Vector2i]:
	var cells := cells_of(uid)
	var found: Array[Vector2i] = []
	for covered in cells:
		for step in STEPS:
			var next := covered + step
			if not cells.has(next) and not found.has(next) and _can_cover([next] as Array[Vector2i], uid):
				found.append(next)
	return found


func add_cell(uid: String, cell: Vector2i) -> bool:
	if not objects.has(uid) or not shape_candidates(uid).has(cell):
		return false
	objects[uid]["extra"].append(cell - objects[uid]["cell"])
	_occupancy[cell] = uid
	return true


func remove_cell(uid: String, cell: Vector2i) -> bool:
	if not objects.has(uid):
		return false
	var extra: Array = objects[uid]["extra"]
	var offset: Vector2i = cell - objects[uid]["cell"]
	if not extra.has(offset):
		return false
	extra.erase(offset)
	if not _is_connected(cells_of(uid)):
		extra.append(offset)
		return false
	_occupancy.erase(cell)
	return true


func _can_cover(cells: Array[Vector2i], ignore_uid: String) -> bool:
	for covered in cells:
		if not is_cell_unlocked(covered):
			return false
		var occupant: String = _occupancy.get(covered, "")
		if occupant != "" and occupant != ignore_uid:
			return false
	return true


func nearest_free_cell(size: Vector2i, start: Vector2i) -> Vector2i:
	for radius in map_size:
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if maxi(absi(dx), absi(dy)) != radius:
					continue
				var candidate := start + Vector2i(dx, dy)
				if can_place(size, candidate):
					return candidate
	return start


func place(uid: String, item_id: String, size: Vector2i, cell: Vector2i) -> bool:
	if objects.has(uid) or not can_place(size, cell):
		return false
	objects[uid] = {"uid": uid, "item_id": item_id, "cell": cell, "size": size, "extra": []}
	_occupy(uid)
	return true


func move(uid: String, cell: Vector2i) -> bool:
	if not can_move(uid, cell):
		return false
	_release(uid)
	objects[uid]["cell"] = cell
	_occupy(uid)
	return true


func remove(uid: String) -> Dictionary:
	if not objects.has(uid) or not animals_in(uid).is_empty():
		return {}
	var entry: Dictionary = objects[uid]
	_release(uid)
	objects.erase(uid)
	return entry


func object_at(cell: Vector2i) -> String:
	return _occupancy.get(cell, "")


func animals_in(enclosure_uid: String) -> Array:
	return animals.values().filter(func(animal: Dictionary) -> bool: return animal["enclosure_uid"] == enclosure_uid)


func add_animal(uid: String, species_id: String, enclosure_uid: String) -> void:
	animals[uid] = {"uid": uid, "species_id": species_id, "enclosure_uid": enclosure_uid}


func to_dict() -> Dictionary:
	var saved_objects: Dictionary = {}
	for uid: String in objects:
		var entry: Dictionary = objects[uid]
		var cell: Vector2i = entry["cell"]
		var size: Vector2i = entry["size"]
		saved_objects[uid] = {"uid": uid, "item_id": entry["item_id"], "cell": [cell.x, cell.y], "size": [size.x, size.y]}
		if not entry["extra"].is_empty():
			saved_objects[uid]["extra"] = entry["extra"].map(func(offset: Vector2i) -> Array: return [offset.x, offset.y])
	return {"map_size": map_size, "unlocked_size": unlocked_size, "objects": saved_objects, "animals": animals.duplicate(true)}


static func from_dict(d: Dictionary) -> ParkModel:
	var park := ParkModel.new(int(d["map_size"]), int(d["unlocked_size"]))
	var saved_objects: Dictionary = d.get("objects", {})
	for uid: String in saved_objects:
		var entry: Dictionary = saved_objects[uid]
		var saved_cell: Array = entry["cell"]
		var saved_size: Array = entry["size"]
		var size := Vector2i(int(saved_size[0]), int(saved_size[1]))
		var cell := Vector2i(int(saved_cell[0]), int(saved_cell[1]))
		var extra: Array = entry.get("extra", []).map(func(offset: Array) -> Vector2i: return Vector2i(int(offset[0]), int(offset[1])))
		park.objects[uid] = {"uid": uid, "item_id": entry["item_id"], "cell": cell, "size": size, "extra": extra}
		park._occupy(uid)
	park.animals = d.get("animals", {}).duplicate(true)
	return park


@warning_ignore("integer_division")
func _margin() -> int:
	return (map_size - unlocked_size) / 2


func _footprint(size: Vector2i, cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in size.x:
		for y in size.y:
			cells.append(cell + Vector2i(x, y))
	return cells


func _cells(entry: Dictionary, cell: Vector2i) -> Array[Vector2i]:
	var cells := _footprint(entry["size"], cell)
	for offset: Vector2i in entry["extra"]:
		cells.append(cell + offset)
	return cells


func _is_connected(cells: Array[Vector2i]) -> bool:
	var reached: Array[Vector2i] = [cells[0]]
	var index := 0
	while index < reached.size():
		for step in STEPS:
			var next := reached[index] + step
			if cells.has(next) and not reached.has(next):
				reached.append(next)
		index += 1
	return reached.size() == cells.size()


func _occupy(uid: String) -> void:
	for covered in cells_of(uid):
		_occupancy[covered] = uid


func _release(uid: String) -> void:
	for covered in cells_of(uid):
		_occupancy.erase(covered)
