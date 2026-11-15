class_name Progression
extends RefCounted


static func level_for_xp(cfg: Dictionary, xp: int) -> int:
	var thresholds: Array = cfg["levels"]["xp_thresholds"]
	var level := 1
	for index in thresholds.size():
		if xp >= int(thresholds[index]):
			level = index + 1
	return level


static func xp_for_level(cfg: Dictionary, level: int) -> int:
	var thresholds: Array = cfg["levels"]["xp_thresholds"]
	return int(thresholds[clampi(level, 1, thresholds.size()) - 1])


static func newly_unlocked(catalog: Dictionary, species: Dictionary, old_level: int, new_level: int) -> Array[String]:
	var ids: Array[String] = []
	for definitions: Dictionary in [catalog, species]:
		for id: String in definitions:
			var unlock_level: int = int(definitions[id]["unlock_level"])
			if unlock_level > old_level and unlock_level <= new_level:
				ids.append(id)
	return ids
