class_name SyncBatch
extends RefCounted


static func pending(entries: Array, synced: Dictionary, limit: int) -> Array:
	var result: Array = []
	for entry: Dictionary in entries:
		if result.size() >= limit:
			break
		if not synced.has(entry["key"]):
			result.append(entry)
	return result


static func to_row(entry: Dictionary) -> Dictionary:
	var delta: Dictionary = entry["delta"]
	return {
		"idem_key": entry["key"],
		"delta_coins": int(delta.get("coins", 0)),
		"delta_nature": int(delta.get("nature", 0)),
		"delta_xp": int(delta.get("xp", 0)),
		"reason": entry["reason"],
		"client_at": Time.get_datetime_string_from_unix_time(int(entry["at"])) + "Z",
	}


static func mark_synced(synced: Dictionary, entries: Array, at: int) -> void:
	for entry: Dictionary in entries:
		synced[entry["key"]] = at


static func prune(synced: Dictionary, entries: Array) -> Dictionary:
	var kept: Dictionary = {}
	for entry: Dictionary in entries:
		if synced.has(entry["key"]):
			kept[entry["key"]] = synced[entry["key"]]
	return kept
