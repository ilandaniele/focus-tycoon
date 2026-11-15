class_name NullNotificationBackend
extends NotificationBackend


func schedule(id: String, in_seconds: int, title: String, _body: String) -> void:
	print_verbose("NullNotificationBackend.schedule %s in %ds: %s" % [id, in_seconds, title])


func cancel(id: String) -> void:
	print_verbose("NullNotificationBackend.cancel %s" % id)
