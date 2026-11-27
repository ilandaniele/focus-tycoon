class_name BenchmarkPark
extends RefCounted

const OBJECT_COUNT := 150
const ANIMAL_COUNT := 75
const DAY_SECONDS := 86400
const DEMO_FOCUS_MINUTES: Array[int] = [50, 25, 75, 40, 100, 60, 45]
const DEMO_MODES: Array[String] = ["study", "work", "reading", "project"]
const DEMO_MEDITATION_SECONDS: Array[int] = [300, 0, 600, 300, 0, 900, 300]


static func build(map_size: int, catalog: Dictionary, species: Dictionary) -> ParkModel:
	var park := ParkModel.new(map_size, map_size)
	var enclosures := _enclosures_by_biome(catalog)
	var decorations := _sorted_items(catalog, func(item: Dictionary) -> bool: return item["category"] != "enclosure")
	var species_ids: Array = species.keys()
	for index in ANIMAL_COUNT:
		var species_id: String = species_ids[index % species_ids.size()]
		var uid := _enclosure_with_room(park, enclosures[species[species_id]["biome"]])
		park.add_animal("b_a_%d" % index, species_id, uid)
	while park.objects.size() < OBJECT_COUNT:
		_place(park, decorations[park.objects.size() % decorations.size()])
	return park


static func _place(park: ParkModel, item: Dictionary) -> String:
	var uid := "b_o_%d" % park.objects.size()
	var size := Vector2i(int(item["size"][0]), int(item["size"][1]))
	park.place(uid, item["id"], size, park.nearest_free_cell(size, Vector2i.ZERO))
	return uid


static func _sorted_items(catalog: Dictionary, keep: Callable) -> Array:
	var items := catalog.values().filter(keep)
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["id"] < b["id"])
	return items


static func _enclosure_with_room(park: ParkModel, enclosure: Dictionary) -> String:
	for uid: String in park.objects:
		if park.objects[uid]["item_id"] == enclosure["id"] and park.animals_in(uid).size() < int(enclosure["capacity"]):
			return uid
	return _place(park, enclosure)


static func _enclosures_by_biome(catalog: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for item: Dictionary in catalog.values():
		if item["category"] == "enclosure":
			result[item["biome"]] = item
	return result


static func demo_focus_sessions(now: int) -> Array:
	var sessions: Array = []
	for index in DEMO_FOCUS_MINUTES.size():
		var minutes := DEMO_FOCUS_MINUTES[index]
		var ended_at := _demo_ended_at(now, index)
		sessions.append({
			"id": "b_f_%d" % index, "mode": DEMO_MODES[index % DEMO_MODES.size()], "planned_min": minutes,
			"effective_min": float(minutes), "status": "interrupted" if index == 1 else "completed",
			"started_at": ended_at - minutes * 60, "ended_at": ended_at, "cycle": 1,
		})
	return sessions


static func demo_meditation_sessions(now: int) -> Array:
	var sessions: Array = []
	for index in DEMO_MEDITATION_SECONDS.size():
		var seconds := DEMO_MEDITATION_SECONDS[index]
		if seconds == 0:
			continue
		var ended_at := _demo_ended_at(now, index)
		sessions.append({
			"id": "b_m_%d" % index, "exercise": "box", "planned_min": seconds / 60, "seconds": seconds,
			"status": "completed", "started_at": ended_at - seconds, "ended_at": ended_at,
		})
	return sessions


static func _demo_ended_at(now: int, index: int) -> int:
	return now - (DEMO_FOCUS_MINUTES.size() - 1 - index) * DAY_SECONDS
