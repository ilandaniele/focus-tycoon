class_name Scenery
extends RefCounted

const OPEN_GROUND := {
	"terrain/grass": 10,
	"terrain/grass_shade": 5,
	"terrain/grass_tufts": 3,
	"terrain/grass_flowers": 2,
}
const WILD_GROUND := {
	"terrain/locked": 3,
	"terrain/locked_tufts": 2,
}
const TALL_PROPS := {
	"objects/tree_pine": 4,
	"objects/tree_oak": 3,
}
const LOW_PROPS := {
	"objects/fern": 3,
	"objects/rock_mossy": 2,
	"objects/bush_flower": 1,
}
const PROP_CHANCE := 0.45
const TALL_SHARE := 0.6
const PROP_TINT := Color(0.86, 0.92, 0.86)

enum Roll { GROUND, PROP, PROP_KIND, PROP_PICK }


static func ground_keys() -> Array[String]:
	var keys: Array[String] = []
	keys.append_array(OPEN_GROUND.keys())
	keys.append_array(WILD_GROUND.keys())
	return keys


static func ground_key(cell: Vector2i, unlocked: bool) -> String:
	return _pick(OPEN_GROUND if unlocked else WILD_GROUND, _roll(cell, Roll.GROUND))


static func prop_key(cell: Vector2i, near_open_ground: bool) -> String:
	if _roll(cell, Roll.PROP) >= PROP_CHANCE:
		return ""
	var tall := not near_open_ground and _roll(cell, Roll.PROP_KIND) < TALL_SHARE
	return _pick(TALL_PROPS if tall else LOW_PROPS, _roll(cell, Roll.PROP_PICK))


static func _roll(cell: Vector2i, salt: Roll) -> float:
	return float(hash([cell.x, cell.y, salt]) % 10000) / 10000.0


static func _pick(weights: Dictionary, roll: float) -> String:
	var total := 0
	for weight: int in weights.values():
		total += weight
	var threshold := roll * total
	for key: String in weights:
		threshold -= weights[key]
		if threshold < 0.0:
			return key
	return weights.keys().back()
