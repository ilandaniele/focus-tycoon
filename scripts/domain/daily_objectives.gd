class_name DailyObjectives
extends RefCounted

const LCG_MULTIPLIER := 1103515245
const LCG_INCREMENT := 12345
const LCG_MASK := 0x7fffffff


static func pick(pool: Array, day: String, count: int = 3) -> Array[String]:
	var ids: Array[String] = []
	for def: Dictionary in pool:
		ids.append(def["id"])
	var state: int = DayKey.seed_of(day)
	for index in range(ids.size() - 1, 0, -1):
		state = (state * LCG_MULTIPLIER + LCG_INCREMENT) & LCG_MASK
		var swap_with: int = (state >> 8) % (index + 1)
		var held: String = ids[index]
		ids[index] = ids[swap_with]
		ids[swap_with] = held
	return ids.slice(0, mini(count, ids.size()))


static func progress(def: Dictionary, metrics: Dictionary) -> Dictionary:
	var current: float = float(metrics.get(def["metric"], 0))
	var target: float = float(def["target"])
	return {"current": current, "target": target, "done": current >= target}
