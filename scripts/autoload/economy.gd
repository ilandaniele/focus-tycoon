extends Node

signal resources_changed(balances: Dictionary)
signal level_up(level: int, unlocked: Array)
signal objectives_changed
signal achievement_earned(id: String)

var _checking_achievements := false


func grant(key: String, delta: Dictionary, reason: String) -> Dictionary:
	return _apply(key, delta, reason)


func spend(key: String, cost: Dictionary, reason: String) -> Dictionary:
	var delta: Dictionary = {}
	for resource: String in cost:
		delta[resource] = -int(cost[resource])
	return _apply(key, delta, reason)


func balance(resource: String) -> int:
	return GameState.ledger.get_balance(resource)


func level() -> int:
	return Progression.level_for_xp(Config.economy, balance("xp"))


func day_metrics(day: String) -> Dictionary:
	var tz: int = GameState.clock.tz_offset_seconds()
	var min_reward: float = float(Config.economy["focus"]["min_reward_minutes"])
	var min_seconds: int = int(Config.economy["meditation"]["min_seconds"])
	return {
		"sessions_completed": Stats.completed_count(GameState.focus_sessions, day, tz),
		"focus_minutes": Stats.rewarded_focus_minutes(GameState.focus_sessions, day, tz, min_reward),
		"meditation_minutes": Stats.meditation_minutes(GameState.meditation_sessions, day, tz, min_seconds),
		"objects_placed": int(GameState.progress["objects_placed_by_day"].get(day, 0)),
	}


func objectives_today() -> Array:
	var day := GameState.today()
	var metrics := day_metrics(day)
	var pool: Array = Config.objectives["daily_pool"]
	var result: Array = []
	for id in DailyObjectives.pick(pool, day, int(Config.objectives["daily_count"])):
		var def: Dictionary = _find(pool, id)
		var entry: Dictionary = def.duplicate()
		entry.merge(DailyObjectives.progress(def, metrics))
		entry["claimed"] = GameState.ledger.has_key(_daily_key(day, id))
		result.append(entry)
	return result


func claim_objective(id: String) -> Dictionary:
	for entry: Dictionary in objectives_today():
		if entry["id"] != id:
			continue
		if entry["claimed"]:
			return {"ok": false, "error": "already_claimed"}
		if not entry["done"]:
			return {"ok": false, "error": "not_done"}
		var result := grant(_daily_key(GameState.today(), id), entry["reward"], "objective")
		objectives_changed.emit()
		return {"ok": result["ok"], "error": result["error"], "reward": entry["reward"]}
	return {"ok": false, "error": "not_done"}


func mission_chains() -> Array:
	var metrics := totals()
	var result: Array = []
	for chain: Dictionary in Config.objectives["mission_chains"]:
		result.append(MissionChains.current(chain, _claimed_steps(chain), metrics))
	return result


func claim_mission(chain_id: String) -> Dictionary:
	var chain := _find(Config.objectives["mission_chains"], chain_id)
	if chain.is_empty():
		return {"ok": false, "error": "unknown_mission"}
	var entry := MissionChains.current(chain, _claimed_steps(chain), totals())
	if not entry.get("done", false):
		return {"ok": false, "error": "not_done"}
	var result := grant(_mission_key(chain_id, entry["step"]), entry["reward"], "mission")
	return {"ok": result["ok"], "error": result["error"], "reward": entry["reward"]}


func check_achievements() -> void:
	if _checking_achievements:
		return
	_checking_achievements = true
	var earned: Dictionary = GameState.progress["achievements"]
	var defs: Array = Config.objectives["achievements"]
	var fresh := Achievements.evaluate(defs, totals(), earned)
	while not fresh.is_empty():
		for id in fresh:
			earned[id] = GameState.now()
			_apply("ach:" + id, _find(defs, id)["reward"], "achievement")
			achievement_earned.emit(id)
		fresh = Achievements.evaluate(defs, totals(), earned)
	_checking_achievements = false


func totals() -> Dictionary:
	var tz: int = GameState.clock.tz_offset_seconds()
	var min_reward: float = float(Config.economy["focus"]["min_reward_minutes"])
	var min_seconds: int = int(Config.economy["meditation"]["min_seconds"])
	var focus_minutes := 0.0
	var completed := 0
	for session: Dictionary in GameState.focus_sessions:
		if float(session["effective_min"]) >= min_reward:
			focus_minutes += float(session["effective_min"])
		if session["status"] == "completed":
			completed += 1
	var species_ids: Dictionary = {}
	for animal: Dictionary in GameState.park.animals.values():
		species_ids[animal["species_id"]] = true
	return {
		"sessions_completed_total": completed,
		"focus_minutes_total": focus_minutes,
		"animals_total": GameState.park.animals.size(),
		"objects_total": GameState.park.objects.size(),
		"species_distinct": species_ids.size(),
		"meditation_days_distinct": Stats.distinct_meditation_days(GameState.meditation_sessions, tz, min_seconds),
		"level": level(),
	}


func _apply(key: String, delta: Dictionary, reason: String) -> Dictionary:
	var old_level := level()
	var result := GameState.ledger.apply(key, delta, reason, GameState.now())
	if not result["ok"] or result["duplicate"]:
		return result
	GameState.mark_dirty()
	resources_changed.emit(GameState.ledger.balances)
	var new_level := level()
	if new_level > old_level:
		level_up.emit(new_level, Progression.newly_unlocked(Config.catalog, Config.species, old_level, new_level))
	check_achievements()
	objectives_changed.emit()
	return result


func _find(defs: Array, id: String) -> Dictionary:
	for def: Dictionary in defs:
		if def["id"] == id:
			return def
	return {}


func _daily_key(day: String, id: String) -> String:
	return "daily:%s:%s" % [day, id]


func _claimed_steps(chain: Dictionary) -> int:
	var claimed := 0
	while claimed < chain["steps"].size() and GameState.ledger.has_key(_mission_key(chain["id"], claimed)):
		claimed += 1
	return claimed


func _mission_key(chain_id: String, step: int) -> String:
	return "mission:%s:%d" % [chain_id, step]
