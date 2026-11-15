extends Node

signal started
signal ticked(remaining_s: int)
signal phase_changed(state: int)
signal focus_finished(record: Dictionary, reward: Dictionary)

const NOTIFICATION_ID := "focus_phase"

var pending_summaries: Array = []

var _ui_timer: Timer


func _ready() -> void:
	_ui_timer = Timer.new()
	_ui_timer.wait_time = 1.0
	_ui_timer.timeout.connect(_on_ui_tick)
	add_child(_ui_timer)
	_ui_timer.start()
	GameState.state_loaded.connect(_on_state_loaded)
	tick_now.call_deferred()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST:
			tick_now()
			GameState.save_now()
			_schedule_phase_notification()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			_platform_call("cancel_notification", [NOTIFICATION_ID])
			tick_now()


func start(minutes: int, mode: String, cycles: int = 1, break_min: int = 0) -> Dictionary:
	if is_active():
		return {"ok": false, "error": "session_active"}
	var focus: Dictionary = Config.economy["focus"]
	if minutes < int(focus["min_minutes"]) or minutes > int(focus["max_minutes"]):
		return {"ok": false, "error": "invalid_minutes"}
	GameState.timer.start(GameState.now(), GameState.new_uid("s"), minutes, mode, cycles, break_min)
	GameState.save_now()
	started.emit()
	phase_changed.emit(state())
	return {"ok": true, "error": ""}


func pause() -> void:
	tick_now()
	GameState.timer.pause(GameState.now())
	_phase_updated()


func resume() -> void:
	GameState.timer.resume(GameState.now())
	_phase_updated()


func interrupt() -> void:
	tick_now()
	if not is_active():
		return
	var record := GameState.timer.interrupt(GameState.now())
	if not record.is_empty():
		_finish_record(record)
	_phase_updated()


func skip_break() -> void:
	GameState.timer.skip_break(GameState.now())
	_phase_updated()


func state() -> int:
	return GameState.timer.state


func remaining_s() -> int:
	return GameState.timer.remaining_s(GameState.now())


func is_active() -> bool:
	return state() in [FocusTimer.State.FOCUS, FocusTimer.State.PAUSED, FocusTimer.State.BREAK]


func take_pending_summaries() -> Array:
	var summaries := pending_summaries
	pending_summaries = []
	return summaries


func tick_now() -> void:
	if not is_active():
		return
	for event: Dictionary in GameState.timer.tick(GameState.now()):
		_handle_event(event)


func _handle_event(event: Dictionary) -> void:
	match event["type"]:
		"focus_completed":
			_finish_record(event["record"])
		"clock_anomaly":
			if not event["record"].is_empty():
				_finish_record(event["record"])
			phase_changed.emit(state())
		"break_started":
			phase_changed.emit(FocusTimer.State.BREAK)
		"break_completed":
			phase_changed.emit(FocusTimer.State.FOCUS)
		"plan_finished":
			phase_changed.emit(FocusTimer.State.FINISHED)


func _finish_record(record: Dictionary) -> void:
	var key := "focus:" + str(record["id"])
	if GameState.ledger.has_key(key):
		return
	var tz: int = GameState.clock.tz_offset_seconds()
	var day := DayKey.of(int(record["ended_at"]), tz)
	var min_reward: float = float(Config.economy["focus"]["min_reward_minutes"])
	var rewarded_min := Stats.rewarded_focus_minutes(GameState.focus_sessions, day, tz, min_reward)
	var reward := RewardCalculator.focus_reward(Config.economy, float(record["effective_min"]), record["status"] == "completed", rewarded_min)
	GameState.add_focus_session(record)
	Economy.grant(key, {"coins": reward["coins"], "nature": reward["nature"], "xp": reward["xp"]}, "focus")
	pending_summaries.append({"record": record, "reward": reward})
	GameState.save_now()
	focus_finished.emit(record, reward)


func _phase_updated() -> void:
	GameState.save_now()
	phase_changed.emit(state())
	ticked.emit(remaining_s())


func _schedule_phase_notification() -> void:
	if is_active() and state() != FocusTimer.State.PAUSED:
		_platform_call("schedule_notification", [NOTIFICATION_ID, remaining_s(), tr("focus.notify_title"), tr("focus.notify_body")])


func _platform_call(method: String, args: Array) -> void:
	if has_node("/root/Platform"):
		get_node("/root/Platform").callv(method, args)


func _on_state_loaded() -> void:
	pending_summaries = []
	tick_now.call_deferred()


func _on_ui_tick() -> void:
	if not is_active():
		return
	tick_now()
	ticked.emit(remaining_s())
