class_name Ints
extends RefCounted


static func of(value: Variant) -> Variant:
	if value is float:
		return int(value)
	if value is Array:
		return value.map(Ints.of)
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value:
			result[key] = Ints.of(value[key])
		return result
	return value
