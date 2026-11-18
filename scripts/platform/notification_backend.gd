class_name NotificationBackend
extends RefCounted


func schedule(_id: String, _in_seconds: int, _title: String, _body: String, _repeat_seconds: int = 0) -> void:
	pass


func cancel(_id: String) -> void:
	pass


func request_permission() -> void:
	pass
