extends Node

signal finished(record: Dictionary, reward: Dictionary)

var _exercise: Dictionary = {}
var _phases: Array = []
var _minutes: int = 0
var _started_at: int = 0


func start(exercise_id: String, minutes: int) -> Dictionary:
	if not _exercise.is_empty():
		return {"ok": false, "error": "session_active"}
	if not Config.meditations.has(exercise_id):
		return {"ok": false, "error": "invalid_exercise"}
	_exercise = Config.meditations[exercise_id]
	_phases = _expand(_exercise.get("phases", []))
	_minutes = minutes
	_started_at = GameState.now()
	return {"ok": true, "error": ""}


func finish(completed: bool) -> Dictionary:
	if _exercise.is_empty():
		return {"ok": false, "error": "not_active"}
	var ended_at := GameState.now()
	var planned_s := _minutes * 60
	var seconds: int = planned_s if completed else clampi(ended_at - _started_at, 0, planned_s)
	var tz: int = GameState.clock.tz_offset_seconds()
	var min_seconds: int = int(Config.economy["meditation"]["min_seconds"])
	var rewarded_min := Stats.meditation_minutes(GameState.meditation_sessions, DayKey.of(ended_at, tz), tz, min_seconds)
	var reward := RewardCalculator.meditation_reward(Config.economy, seconds, rewarded_min)
	var record: Dictionary = {
		"id": GameState.new_uid("m"), "exercise": _exercise["id"], "planned_min": _minutes, "seconds": seconds,
		"status": "completed" if completed else "interrupted", "started_at": _started_at, "ended_at": ended_at,
	}
	_exercise = {}
	GameState.add_meditation_session(record)
	Economy.grant("meditation:" + str(record["id"]), {"coins": reward["coins"], "nature": reward["nature"], "xp": reward["xp"]}, "meditation")
	GameState.save_now()
	finished.emit(record, reward)
	return {"ok": true, "error": "", "record": record, "reward": reward}


func phase_at(elapsed_s: int) -> Dictionary:
	if _exercise.is_empty():
		return {}
	if _exercise["kind"] == "breath":
		return _breath_phase(elapsed_s)
	return _guided_phase(elapsed_s)


func _expand(phases: Array) -> Array:
	var flat: Array = []
	for phase: Dictionary in phases:
		if phase.has("repeat"):
			for _round in int(phase["repeat"]):
				flat.append_array(_expand(phase["phases"]))
		else:
			flat.append(phase)
	return flat


func _breath_phase(elapsed_s: int) -> Dictionary:
	var cycle_s := 0
	for phase: Dictionary in _phases:
		cycle_s += int(phase["seconds"])
	var into_cycle: int = elapsed_s % cycle_s
	for index in _phases.size():
		var seconds: int = int(_phases[index]["seconds"])
		if into_cycle < seconds:
			return {"name": _phases[index]["name"], "index": index, "seconds": seconds, "elapsed": into_cycle, "progress": float(into_cycle) / seconds}
		into_cycle -= seconds
	return {}


func _guided_phase(elapsed_s: int) -> Dictionary:
	var prompts: Array = _exercise["prompts"]
	var every_s: int = int(_exercise["prompt_every_s"])
	@warning_ignore("integer_division")
	var index: int = (elapsed_s / every_s) % prompts.size()
	var into_prompt: int = elapsed_s % every_s
	return {"name": "prompt", "prompt": prompts[index], "index": index, "seconds": every_s, "elapsed": into_prompt, "progress": float(into_prompt) / every_s}
