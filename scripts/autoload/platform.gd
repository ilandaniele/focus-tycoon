extends Node

var store: StoreService = MockStore.new()
var _notifications: NotificationBackend = NullNotificationBackend.new()


func haptic(ms: int) -> void:
	if not GameState.settings.get("vibration", true):
		return
	if not DisplayServer.is_touchscreen_available():
		return
	Input.vibrate_handheld(ms)


func schedule_notification(id: String, in_s: int, title: String, body: String) -> void:
	_notifications.schedule(id, in_s, title, body)


func cancel_notification(id: String) -> void:
	_notifications.cancel(id)
