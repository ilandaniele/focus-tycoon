class_name SessionSummary
extends RefCounted

const REWARD_KEYS: Array[String] = ["coins", "nature", "xp"]


static func build(entries: Array) -> Dictionary:
	var minutes := 0.0
	var totals := {}
	var capped := false
	for entry: Dictionary in entries:
		var reward: Dictionary = entry.get("reward", {})
		minutes += _minutes(entry["kind"], entry.get("record", {}))
		capped = capped or bool(reward.get("capped", false))
		for key in REWARD_KEYS:
			totals[key] = int(totals.get(key, 0)) + int(reward.get(key, 0))
	var whole_minutes := int(minutes)
	var tone := _tone(_status(entries.back()), whole_minutes)
	return {
		"minutes": whole_minutes,
		"rewards": _positive(totals),
		"capped": capped,
		"title_key": "summary.title_" + tone,
		"message_key": "summary.msg_" + tone,
	}


static func _tone(status: String, minutes: int) -> String:
	if status == "completed":
		return "done"
	return "early" if minutes == 0 else "partial"


static func _positive(totals: Dictionary) -> Dictionary:
	var shown := {}
	for key in REWARD_KEYS:
		if int(totals[key]) > 0:
			shown[key] = totals[key]
	return shown


static func _status(entry: Dictionary) -> String:
	var record: Dictionary = entry.get("record", {})
	return record.get("status", "completed")


static func _minutes(kind: String, record: Dictionary) -> float:
	if kind == "meditation":
		return float(record.get("seconds", 0)) / 60.0
	return float(record.get("effective_min", 0.0))
