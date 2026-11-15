class_name Clock
extends RefCounted


func now() -> int:
	return int(Time.get_unix_time_from_system())


func tz_offset_seconds() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60
