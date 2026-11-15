class_name Achievements
extends RefCounted


static func evaluate(defs: Array, totals: Dictionary, earned: Dictionary) -> Array[String]:
	var newly_earned: Array[String] = []
	for def: Dictionary in defs:
		if not earned.has(def["id"]) and DailyObjectives.progress(def, totals)["done"]:
			newly_earned.append(def["id"])
	return newly_earned
