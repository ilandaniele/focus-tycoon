class_name DayKey
extends RefCounted

const SECONDS_PER_DAY := 86400


static func of(unix: int, tz_offset: int) -> String:
	return _from_ordinal(floori((unix + tz_offset) / float(SECONDS_PER_DAY)))


static func add_days(day: String, n: int) -> String:
	return _from_ordinal(_to_ordinal(day) + n)


static func seed_of(day: String) -> int:
	return day.replace("-", "").to_int()


@warning_ignore("integer_division")
static func _to_ordinal(day: String) -> int:
	var parts := day.split("-")
	var year: int = parts[0].to_int()
	var month: int = parts[1].to_int()
	var dom: int = parts[2].to_int()
	if month <= 2:
		year -= 1
	var era: int = floori(year / 400.0)
	var year_of_era: int = year - era * 400
	var day_of_year: int = (153 * (month + (-3 if month > 2 else 9)) + 2) / 5 + dom - 1
	var day_of_era: int = year_of_era * 365 + year_of_era / 4 - year_of_era / 100 + day_of_year
	return era * 146097 + day_of_era - 719468


@warning_ignore("integer_division")
static func _from_ordinal(ordinal: int) -> String:
	var z: int = ordinal + 719468
	var era: int = floori(z / 146097.0)
	var day_of_era: int = z - era * 146097
	var year_of_era: int = (day_of_era - day_of_era / 1460 + day_of_era / 36524 - day_of_era / 146096) / 365
	var day_of_year: int = day_of_era - (365 * year_of_era + year_of_era / 4 - year_of_era / 100)
	var mp: int = (5 * day_of_year + 2) / 153
	var dom: int = day_of_year - (153 * mp + 2) / 5 + 1
	var month: int = mp + 3 if mp < 10 else mp - 9
	var year: int = year_of_era + era * 400 + (1 if month <= 2 else 0)
	return "%04d-%02d-%02d" % [year, month, dom]
