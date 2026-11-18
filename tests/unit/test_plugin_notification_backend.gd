extends TestCase

var _scheduler: FakeNotificationScheduler
var _backend: PluginNotificationBackend


func before_each() -> void:
	_scheduler = FakeNotificationScheduler.new()
	_backend = PluginNotificationBackend.new(_scheduler)


func after_each() -> void:
	_scheduler.free()


func test_creates_channel_on_initialization() -> void:
	assert_eq(_scheduler.channels.size(), 1)
	assert_eq(_scheduler.channels[0][NotificationChannel.DATA_KEY_ID], PluginNotificationBackend.CHANNEL_ID)


func test_schedule_maps_fields_and_requests_permission() -> void:
	_backend.schedule("focus_phase", 1500, "Done", "Session finished")
	var data: Dictionary = _scheduler.scheduled[0]
	assert_eq(data["notification_id"], PluginNotificationBackend.numeric_id("focus_phase"))
	assert_eq(data["channel_id"], PluginNotificationBackend.CHANNEL_ID)
	assert_eq(data["title"], "Done")
	assert_eq(data["content"], "Session finished")
	assert_eq(data["delay"], 1500)
	assert_false(data.has("interval"))
	assert_eq(_scheduler.permission_requests, 1)


func test_schedule_with_permission_does_not_ask_again() -> void:
	_scheduler.permission = true
	_backend.schedule("daily_reminder", 60, "Hi", "Body", 86400)
	assert_eq(_scheduler.permission_requests, 0)
	assert_eq(_scheduler.scheduled[0]["interval"], 86400)


func test_cancel_uses_same_numeric_id() -> void:
	_backend.cancel("focus_phase")
	assert_eq(_scheduler.cancelled, [PluginNotificationBackend.numeric_id("focus_phase")] as Array[int])


func test_numeric_ids_are_stable_positive_and_distinct() -> void:
	var focus := PluginNotificationBackend.numeric_id("focus_phase")
	assert_eq(focus, PluginNotificationBackend.numeric_id("focus_phase"))
	assert_true(focus >= 0)
	assert_true(focus != PluginNotificationBackend.numeric_id("daily_reminder"))


func test_request_permission_asks_only_when_missing() -> void:
	_backend.request_permission()
	assert_eq(_scheduler.permission_requests, 1)
	_scheduler.permission = true
	_backend.request_permission()
	assert_eq(_scheduler.permission_requests, 1)
