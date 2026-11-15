class_name Stats
extends RefCounted


static func daily_focus_minutes(sessions: Array, last_day: String, days: int, tz: int) -> Array:
	var by_day: Dictionary = {}
	for session: Dictionary in sessions:
		var day: String = _day_of(session, tz)
		by_day[day] = float(by_day.get(day, 0.0)) + float(session["effective_min"])
	var result: Array = []
	for offset in range(days - 1, -1, -1):
		var day: String = DayKey.add_days(last_day, -offset)
		result.append({"day": day, "minutes": float(by_day.get(day, 0.0))})
	return result


static func summary(sessions: Array, from_day: String, to_day: String, tz: int) -> Dictionary:
	var result: Dictionary = {"total_min": 0.0, "completed": 0, "interrupted": 0, "by_mode": {}}
	var by_mode: Dictionary = result["by_mode"]
	for session: Dictionary in sessions:
		var day: String = _day_of(session, tz)
		if day < from_day or day > to_day:
			continue
		var minutes: float = float(session["effective_min"])
		result["total_min"] = float(result["total_min"]) + minutes
		result[session["status"]] = int(result[session["status"]]) + 1
		by_mode[session["mode"]] = float(by_mode.get(session["mode"], 0.0)) + minutes
	return result


static func rewarded_focus_minutes(sessions: Array, day: String, tz: int, min_effective: float) -> float:
	var total := 0.0
	for session: Dictionary in sessions:
		var minutes: float = float(session["effective_min"])
		if _day_of(session, tz) == day and minutes >= min_effective:
			total += minutes
	return total


static func completed_count(sessions: Array, day: String, tz: int) -> int:
	return sessions.filter(func(session: Dictionary) -> bool:
		return session["status"] == "completed" and _day_of(session, tz) == day).size()


static func meditation_minutes(sessions: Array, day: String, tz: int, min_seconds: int) -> float:
	var total := 0.0
	for session: Dictionary in sessions:
		if _day_of(session, tz) == day and int(session["seconds"]) >= min_seconds:
			total += int(session["seconds"]) / 60.0
	return total


static func distinct_meditation_days(sessions: Array, tz: int, min_seconds: int) -> int:
	var days: Dictionary = {}
	for session: Dictionary in sessions:
		if int(session["seconds"]) >= min_seconds:
			days[_day_of(session, tz)] = true
	return days.size()


static func _day_of(session: Dictionary, tz: int) -> String:
	return DayKey.of(int(session["ended_at"]), tz)
