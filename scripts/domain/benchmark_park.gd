class_name BenchmarkPark
extends RefCounted

const OBJECT_COUNT := 150
const ANIMAL_COUNT := 20


static func build(map_size: int, catalog: Dictionary, species: Dictionary) -> ParkModel:
	var park := ParkModel.new(map_size, map_size)
	var enclosures := _sorted_items(catalog, func(item: Dictionary) -> bool: return item["category"] == "enclosure")
	var decorations := _sorted_items(catalog, func(item: Dictionary) -> bool: return item["category"] != "enclosure")
	var species_by_biome := _species_by_biome(species)
	var adopted := 0
	while adopted < ANIMAL_COUNT:
		var enclosure: Dictionary = enclosures[park.objects.size() % enclosures.size()]
		var uid := _place(park, enclosure)
		var residents: Array = species_by_biome[enclosure["biome"]]
		for slot in mini(int(enclosure["capacity"]), ANIMAL_COUNT - adopted):
			park.add_animal("b_a_%d" % (adopted + slot), residents[(adopted + slot) % residents.size()], uid)
		adopted = park.animals.size()
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


static func _species_by_biome(species: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for definition: Dictionary in species.values():
		if not result.has(definition["biome"]):
			result[definition["biome"]] = []
		result[definition["biome"]].append(definition["id"])
	return result
