class_name FocusTimer
extends RefCounted

enum State { IDLE, FOCUS, PAUSED, BREAK, FINISHED }

const CLOCK_ANOMALY_S := 120

var state: State = State.IDLE
var _session_id: String = ""
var _mode: String = ""
var _planned_min: int = 0
var _cycles: int = 1
var _break_min: int = 0
var _cycle: int = 1
var _phase_started_at: int = 0
var _paused_total: int = 0
var _paused_at: int = 0
var _last_seen: int = 0


func start(now: int, session_id: String, minutes: int, mode: String, cycles: int = 1, break_min: int = 0) -> void:
	_session_id = session_id
	_mode = mode
	_planned_min = minutes
	_cycles = maxi(1, cycles)
	_break_min = break_min
	_cycle = 1
	_begin_focus(now)
	_last_seen = now


func pause(now: int) -> void:
	if state != State.FOCUS:
		return
	state = State.PAUSED
	_paused_at = now
	_last_seen = now


func resume(now: int) -> void:
	if state != State.PAUSED:
		return
	_paused_total += now - _paused_at
	state = State.FOCUS
	_last_seen = now


func interrupt(now: int) -> Dictionary:
	if state == State.BREAK:
		state = State.IDLE
		return {}
	if state != State.FOCUS and state != State.PAUSED:
		return {}
	var record := _interrupted_record(now)
	state = State.IDLE
	_last_seen = now
	return record


func skip_break(now: int) -> void:
	if state != State.BREAK:
		return
	_cycle += 1
	_begin_focus(now)
	_last_seen = now


func tick(now: int) -> Array:
	var events: Array = []
	if state == State.IDLE or state == State.FINISHED:
		return events
	if now < _last_seen - CLOCK_ANOMALY_S:
		events.append(_anomaly_event())
		return events
	now = maxi(now, _last_seen)
	while true:
		if state == State.FOCUS and now >= _focus_end():
			_complete_focus(events)
		elif state == State.BREAK and now >= _phase_started_at + _break_min * 60:
			events.append({"type": "break_completed"})
			_cycle += 1
			_begin_focus(_phase_started_at + _break_min * 60)
		else:
			break
	_last_seen = now
	return events


func remaining_s(now: int) -> int:
	match state:
		State.FOCUS, State.PAUSED:
			return _planned_min * 60 - elapsed_focus_s(now)
		State.BREAK:
			return clampi(_phase_started_at + _break_min * 60 - now, 0, _break_min * 60)
	return 0


func elapsed_focus_s(now: int) -> int:
	match state:
		State.FOCUS:
			return clampi(now - _phase_started_at - _paused_total, 0, _planned_min * 60)
		State.PAUSED:
			return clampi(_paused_at - _phase_started_at - _paused_total, 0, _planned_min * 60)
	return 0


func to_dict() -> Dictionary:
	return {
		"state": state, "session_id": _session_id, "mode": _mode, "planned_min": _planned_min,
		"cycles": _cycles, "break_min": _break_min, "cycle": _cycle,
		"phase_started_at": _phase_started_at, "paused_total": _paused_total,
		"paused_at": _paused_at, "last_seen": _last_seen,
	}


static func from_dict(d: Dictionary) -> FocusTimer:
	var timer := FocusTimer.new()
	timer.state = int(d.get("state", State.IDLE)) as State
	timer._session_id = str(d.get("session_id", ""))
	timer._mode = str(d.get("mode", ""))
	timer._planned_min = int(d.get("planned_min", 0))
	timer._cycles = int(d.get("cycles", 1))
	timer._break_min = int(d.get("break_min", 0))
	timer._cycle = int(d.get("cycle", 1))
	timer._phase_started_at = int(d.get("phase_started_at", 0))
	timer._paused_total = int(d.get("paused_total", 0))
	timer._paused_at = int(d.get("paused_at", 0))
	timer._last_seen = int(d.get("last_seen", 0))
	return timer


func _begin_focus(at: int) -> void:
	state = State.FOCUS
	_phase_started_at = at
	_paused_total = 0
	_paused_at = 0


func _focus_end() -> int:
	return _phase_started_at + _planned_min * 60 + _paused_total


func _complete_focus(events: Array) -> void:
	var ended_at := _focus_end()
	events.append({"type": "focus_completed", "record": _record("completed", float(_planned_min), ended_at)})
	if _cycle >= _cycles:
		state = State.FINISHED
		events.append({"type": "plan_finished"})
	elif _break_min > 0:
		state = State.BREAK
		_phase_started_at = ended_at
		events.append({"type": "break_started"})
	else:
		_cycle += 1
		_begin_focus(ended_at)


func _interrupted_record(at: int) -> Dictionary:
	return _record("interrupted", elapsed_focus_s(at) / 60.0, at)


func _anomaly_event() -> Dictionary:
	var record: Dictionary = {}
	if state == State.FOCUS or state == State.PAUSED:
		record = _interrupted_record(_last_seen)
	state = State.IDLE
	return {"type": "clock_anomaly", "record": record}


func _record(status: String, effective_min: float, ended_at: int) -> Dictionary:
	return {
		"id": "%s#%d" % [_session_id, _cycle], "mode": _mode, "planned_min": _planned_min,
		"effective_min": effective_min, "status": status,
		"started_at": _phase_started_at, "ended_at": ended_at, "cycle": _cycle,
	}
