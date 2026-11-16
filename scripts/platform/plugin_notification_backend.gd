class_name PluginNotificationBackend
extends NotificationBackend

const SINGLETON := "NotificationSchedulerPlugin"
const CHANNEL_ID := "focus_tycoon_reminders"
const IMPORTANCE_DEFAULT := 3

var _scheduler: Node


static func available() -> bool:
	return Engine.has_singleton(SINGLETON)


static func numeric_id(id: String) -> int:
	return id.hash() & 0x7FFFFFFF


func _init(scheduler: Node) -> void:
	_scheduler = scheduler
	_scheduler.initialization_completed.connect(_create_channel)
	_scheduler.initialize()


func schedule(id: String, in_seconds: int, title: String, body: String, repeat_seconds: int = 0) -> void:
	if not _scheduler.has_post_notifications_permission():
		_scheduler.request_post_notifications_permission()
	var data := NotificationData.new() \
		.set_id(numeric_id(id)) \
		.set_channel_id(CHANNEL_ID) \
		.set_title(title) \
		.set_content(body) \
		.set_delay(maxi(in_seconds, 1))
	if repeat_seconds > 0:
		data.set_interval(repeat_seconds)
	_scheduler.schedule(data)


func cancel(id: String) -> void:
	_scheduler.cancel(numeric_id(id))


func _create_channel() -> void:
	var channel := NotificationChannel.new() \
		.set_id(CHANNEL_ID) \
		.set_name(tr("notify.channel_name")) \
		.set_description(tr("notify.channel_desc")) \
		.set_importance(IMPORTANCE_DEFAULT)
	_scheduler.create_notification_channel(channel)
