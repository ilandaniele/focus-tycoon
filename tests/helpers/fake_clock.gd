class_name FakeClock
extends Clock

var t: int = 1_763_200_000
var tz: int = 0


func now() -> int:
	return t


func tz_offset_seconds() -> int:
	return tz


func advance(seconds: int) -> void:
	t += seconds
