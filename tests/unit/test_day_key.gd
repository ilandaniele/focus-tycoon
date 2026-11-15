extends TestCase


func test_of_epoch_and_known_day() -> void:
	assert_eq(DayKey.of(0, 0), "1970-01-01")
	assert_eq(DayKey.of(1_763_200_000, 0), "2025-11-15")


func test_of_applies_tz_offset() -> void:
	assert_eq(DayKey.of(86399, 0), "1970-01-01")
	assert_eq(DayKey.of(86399, 3600), "1970-01-02")
	assert_eq(DayKey.of(0, -3600), "1969-12-31")


func test_add_days_crosses_month_year_and_leap() -> void:
	assert_eq(DayKey.add_days("2024-02-28", 2), "2024-03-01")
	assert_eq(DayKey.add_days("2025-02-28", 1), "2025-03-01")
	assert_eq(DayKey.add_days("2025-12-31", 1), "2026-01-01")
	assert_eq(DayKey.add_days("2026-01-01", -1), "2025-12-31")
	assert_eq(DayKey.add_days("2025-11-15", 0), "2025-11-15")


func test_add_days_matches_of_over_many_days() -> void:
	var start_day := DayKey.of(1_700_000_000, 0)
	for offset in 800:
		var unix := 1_700_000_000 + offset * DayKey.SECONDS_PER_DAY
		assert_eq(DayKey.add_days(start_day, offset), DayKey.of(unix, 0))
