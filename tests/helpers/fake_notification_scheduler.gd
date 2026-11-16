class_name FakeNotificationScheduler
extends Node

signal initialization_completed

var permission: bool = false
var permission_requests: int = 0
var channels: Array[Dictionary] = []
var scheduled: Array[Dictionary] = []
var cancelled: Array[int] = []


func initialize() -> void:
	initialization_completed.emit()


func create_notification_channel(channel: NotificationChannel) -> Error:
	channels.append(channel.get_raw_data())
	return OK


func has_post_notifications_permission() -> bool:
	return permission


func request_post_notifications_permission() -> Error:
	permission_requests += 1
	return OK


func schedule(data: NotificationData) -> Error:
	scheduled.append(data.get_raw_data())
	return OK


func cancel(id: int) -> Error:
	cancelled.append(id)
	return OK
