extends Node

var store: StoreService = MockStore.new()
var _notifications: NotificationBackend = NullNotificationBackend.new()


func _ready() -> void:
	if GooglePlayStore.available():
		store = GooglePlayStore.new(_attach(BillingClient.new()))
	if PluginNotificationBackend.available():
		_notifications = PluginNotificationBackend.new(_attach(NotificationScheduler.new()))


func haptic(ms: int) -> void:
	if not GameState.settings.get("vibration", true):
		return
	if not DisplayServer.is_touchscreen_available():
		return
	Input.vibrate_handheld(ms)


func schedule_notification(id: String, in_s: int, title: String, body: String, repeat_s: int = 0) -> void:
	_notifications.schedule(id, in_s, title, body, repeat_s)


func cancel_notification(id: String) -> void:
	_notifications.cancel(id)


func request_notification_permission() -> void:
	_notifications.request_permission()


func _attach(child: Node) -> Node:
	add_child(child)
	return child
