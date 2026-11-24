class_name EnclosureSizing
extends RefCounted


static func base_size(item: Dictionary) -> Vector2i:
	return Vector2i(int(item["size"][0]), int(item["size"][1]))


static func base_cells(item: Dictionary) -> int:
	var size := base_size(item)
	return size.x * size.y


static func capacity(item: Dictionary, cell_count: int) -> int:
	var base := int(item["capacity"])
	return maxi(base, floori(float(base * cell_count) / base_cells(item)))


static func cell_cost(item: Dictionary, tuning: Dictionary) -> Dictionary:
	var cost: Dictionary = {}
	for resource: String in item["cost"]:
		cost[resource] = ceili(int(item["cost"][resource]) * float(tuning["cost_ratio"]) / base_cells(item))
	return cost


static func value_coins(item: Dictionary, extra_count: int, tuning: Dictionary) -> int:
	return int(item["cost"].get("coins", 0)) + int(cell_cost(item, tuning).get("coins", 0)) * extra_count
