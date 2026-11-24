extends Node

signal object_placed(uid: String)
signal object_moved(uid: String)
signal object_removed(uid: String)
signal object_resized(uid: String)
signal animal_adopted(uid: String)
signal park_expanded(size: int)


func buy_and_place(item_id: String, cell: Vector2i) -> Dictionary:
	var item := Config.item(item_id)
	if item.is_empty():
		return _fail("invalid_item")
	if Economy.level() < int(item["unlock_level"]):
		return _fail("locked_level")
	if item["premium"] and not GameState.has_entitlement("premium"):
		return _fail("premium_required")
	var size := _size_of(item)
	if not GameState.park.can_place(size, cell):
		return _fail("invalid_cell")
	if not GameState.ledger.can_afford(item["cost"]):
		return _fail("insufficient_funds")
	var uid := GameState.new_uid("o")
	GameState.park.place(uid, item_id, size, cell)
	_count_placement()
	Economy.spend("buy:" + uid, item["cost"], "buy:" + item_id)
	object_placed.emit(uid)
	return {"ok": true, "error": "", "uid": uid}


func move_object(uid: String, cell: Vector2i) -> bool:
	if not GameState.park.move(uid, cell):
		return false
	GameState.mark_dirty()
	object_moved.emit(uid)
	return true


func remove_object(uid: String) -> Dictionary:
	if not GameState.park.objects.has(uid):
		return _fail("invalid_uid")
	if not GameState.park.animals_in(uid).is_empty():
		return _fail("enclosure_not_empty")
	var refund := refund_for(uid)
	GameState.park.remove(uid)
	Economy.grant("refund:" + uid, {"coins": refund}, "refund")
	GameState.mark_dirty()
	object_removed.emit(uid)
	return {"ok": true, "error": "", "refund": refund}


func refund_for(uid: String) -> int:
	var entry: Dictionary = GameState.park.objects[uid]
	var value := EnclosureSizing.value_coins(Config.item(entry["item_id"]), entry["extra"].size(), _growth_tuning())
	return floori(value * float(Config.economy["refund_ratio"]))


func capacity_of(uid: String) -> int:
	return EnclosureSizing.capacity(_item_of(uid), GameState.park.cells_of(uid).size())


func cell_cost_of(uid: String) -> Dictionary:
	return EnclosureSizing.cell_cost(_item_of(uid), _growth_tuning())


func add_enclosure_cell(uid: String, cell: Vector2i) -> Dictionary:
	if not _is_enclosure(uid):
		return _fail("invalid_uid")
	if GameState.park.cells_of(uid).size() >= int(_growth_tuning()["max_cells"]) or not GameState.park.shape_candidates(uid).has(cell):
		return _fail("no_room")
	var cost := cell_cost_of(uid)
	if not GameState.ledger.can_afford(cost):
		return _fail("insufficient_funds")
	GameState.park.add_cell(uid, cell)
	Economy.spend("shape:%s:%d" % [uid, GameState.ledger.entries().size()], cost, "grow:" + GameState.park.objects[uid]["item_id"])
	GameState.mark_dirty()
	object_resized.emit(uid)
	return {"ok": true, "error": ""}


func remove_enclosure_cell(uid: String, cell: Vector2i) -> Dictionary:
	if not _is_enclosure(uid):
		return _fail("invalid_uid")
	var remaining := GameState.park.cells_of(uid).size() - 1
	if EnclosureSizing.capacity(_item_of(uid), remaining) < GameState.park.animals_in(uid).size():
		return _fail("enclosure_full")
	if not GameState.park.remove_cell(uid, cell):
		return _fail("cannot_shrink")
	var refund := floori(int(cell_cost_of(uid).get("coins", 0)) * float(Config.economy["refund_ratio"]))
	Economy.grant("unshape:%s:%d" % [uid, GameState.ledger.entries().size()], {"coins": refund}, "refund")
	GameState.mark_dirty()
	object_resized.emit(uid)
	return {"ok": true, "error": ""}


func _is_enclosure(uid: String) -> bool:
	return GameState.park.objects.has(uid) and _item_of(uid)["category"] == "enclosure"


func _item_of(uid: String) -> Dictionary:
	return Config.item(GameState.park.objects[uid]["item_id"])


func adopt(species_id: String, enclosure_uid: String) -> Dictionary:
	var species: Dictionary = Config.species.get(species_id, {})
	if species.is_empty():
		return _fail("invalid_species")
	if Economy.level() < int(species["unlock_level"]):
		return _fail("locked_level")
	if not _is_matching_enclosure(species, enclosure_uid):
		return _fail("no_enclosure")
	if _free_capacity(enclosure_uid) <= 0:
		return _fail("enclosure_full")
	if not GameState.ledger.can_afford(species["cost"]):
		return _fail("insufficient_funds")
	var uid := GameState.new_uid("a")
	GameState.park.add_animal(uid, species_id, enclosure_uid)
	Economy.spend("adopt:" + uid, species["cost"], "adopt:" + species_id)
	animal_adopted.emit(uid)
	return {"ok": true, "error": "", "uid": uid}


func buy_expansion(id: String) -> Dictionary:
	for expansion: Dictionary in Config.expansions:
		if expansion["id"] != id:
			continue
		if int(expansion["size"]) <= GameState.park.unlocked_size:
			return _fail("already_owned")
		if Economy.level() < int(expansion["unlock_level"]):
			return _fail("locked_level")
		if not GameState.ledger.can_afford(expansion["cost"]):
			return _fail("insufficient_funds")
		GameState.park.unlocked_size = int(expansion["size"])
		Economy.spend("expand:" + id, expansion["cost"], "expand:" + id)
		park_expanded.emit(GameState.park.unlocked_size)
		return {"ok": true, "error": ""}
	return _fail("invalid_expansion")


func enclosures_for(species_id: String) -> Array:
	var species: Dictionary = Config.species.get(species_id, {})
	var result: Array = []
	if species.is_empty():
		return result
	for uid: String in GameState.park.objects:
		if _is_matching_enclosure(species, uid) and _free_capacity(uid) > 0:
			result.append(uid)
	return result


func _is_matching_enclosure(species: Dictionary, uid: String) -> bool:
	if not GameState.park.objects.has(uid):
		return false
	var item := Config.item(GameState.park.objects[uid]["item_id"])
	return item["category"] == "enclosure" and item["biome"] == species["biome"]


func _free_capacity(enclosure_uid: String) -> int:
	return capacity_of(enclosure_uid) - GameState.park.animals_in(enclosure_uid).size()


func _count_placement() -> void:
	var placed: Dictionary = GameState.progress["objects_placed_by_day"]
	var day := GameState.today()
	placed[day] = int(placed.get(day, 0)) + 1


func _growth_tuning() -> Dictionary:
	return Config.economy["enclosure_growth"]


func _size_of(item: Dictionary) -> Vector2i:
	return Vector2i(int(item["size"][0]), int(item["size"][1]))


func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error}
