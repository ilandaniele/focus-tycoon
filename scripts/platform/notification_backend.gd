class_name NotificationBackend
extends RefCounted

# Real backends need unconfirmed native plugins (docs/01 R3); only the null backend ships.


func schedule(_id: String, _in_seconds: int, _title: String, _body: String) -> void:
	pass


func cancel(_id: String) -> void:
	pass
