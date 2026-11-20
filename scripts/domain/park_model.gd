class_name ParkModel
extends RefCounted

var map_size: int
var unlocked_size: int
var objects: Dictionary = {}
var animals: Dictionary = {}
var _occupancy: Dictionary = {}


func _init(p_map_size: int, p_unlocked_size: int) -> void:
	map_size = p_map_size
	unlocked_size = p_unlocked_size


@warning_ignore("integer_division")
func is_cell_unlocked(cell: Vector2i) -> bool:
	var margin: int = (map_size - unlocked_size) / 2
	return cell.x >= margin and cell.y >= margin and cell.x < margin + unlocked_size and cell.y < margin + unlocked_size


func can_place(size: Vector2i, cell: Vector2i, ignore_uid: String = "") -> bool:
	for covered in _footprint(size, cell):
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
	objects[uid] = {"uid": uid, "item_id": item_id, "cell": cell, "size": size}
	_occupy(uid, size, cell)
	return true


func move(uid: String, cell: Vector2i) -> bool:
	if not objects.has(uid):
		return false
	var entry: Dictionary = objects[uid]
	var size: Vector2i = entry["size"]
	if not can_place(size, cell, uid):
		return false
	_release(uid)
	entry["cell"] = cell
	_occupy(uid, size, cell)
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
		park.objects[uid] = {"uid": uid, "item_id": entry["item_id"], "cell": cell, "size": size}
		park._occupy(uid, size, cell)
	park.animals = d.get("animals", {}).duplicate(true)
	return park


func _footprint(size: Vector2i, cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x in size.x:
		for y in size.y:
			cells.append(cell + Vector2i(x, y))
	return cells


func _occupy(uid: String, size: Vector2i, cell: Vector2i) -> void:
	for covered in _footprint(size, cell):
		_occupancy[covered] = uid


func _release(uid: String) -> void:
	var entry: Dictionary = objects[uid]
	for covered in _footprint(entry["size"], entry["cell"]):
		_occupancy.erase(covered)
