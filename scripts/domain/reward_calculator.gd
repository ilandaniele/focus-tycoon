class_name RewardCalculator
extends RefCounted

const EPSILON := 1e-9


static func focus_reward(cfg: Dictionary, effective_min: float, completed: bool, rewarded_today_min: float) -> Dictionary:
	var focus: Dictionary = cfg["focus"]
	if effective_min < float(focus["min_reward_minutes"]):
		return _reward(0.0, 0.0, 0.0, 0.0)
	var tiered := _tiered_minutes(focus["daily_tiers"], rewarded_today_min, rewarded_today_min + effective_min)
	var coins_factor: float = 1.0 + float(focus["completion_bonus"])
	var other_factor := 1.0
	if not completed:
		coins_factor = float(focus["interrupted_multiplier"])
		other_factor = coins_factor
	return _reward(
		tiered * float(focus["coins_per_min"]) * coins_factor,
		tiered * float(focus["nature_per_min"]) * other_factor,
		tiered * float(focus["xp_per_min"]) * other_factor,
		effective_min)


static func meditation_reward(cfg: Dictionary, seconds: int, rewarded_today_min: float) -> Dictionary:
	var meditation: Dictionary = cfg["meditation"]
	if seconds < int(meditation["min_seconds"]):
		return _reward(0.0, 0.0, 0.0, 0.0)
	var remaining := maxf(0.0, float(meditation["daily_cap_min"]) - rewarded_today_min)
	var counted := minf(seconds / 60.0, remaining)
	return _reward(
		counted * float(meditation["coins_per_min"]),
		counted * float(meditation["nature_per_min"]),
		counted * float(meditation["xp_per_min"]),
		counted)


static func max_daily_focus_coins(cfg: Dictionary) -> int:
	var focus: Dictionary = cfg["focus"]
	var tiers: Array = focus["daily_tiers"]
	var last_limit: float = float(tiers[tiers.size() - 1]["up_to_min"])
	var tiered := _tiered_minutes(tiers, 0.0, last_limit)
	return _floor(tiered * float(focus["coins_per_min"]) * (1.0 + float(focus["completion_bonus"])))


static func _tiered_minutes(tiers: Array, from_min: float, to_min: float) -> float:
	var total := 0.0
	var lower := 0.0
	for tier: Dictionary in tiers:
		var upper: float = float(tier["up_to_min"])
		total += maxf(0.0, minf(to_min, upper) - maxf(from_min, lower)) * float(tier["multiplier"])
		lower = upper
	return total


static func _reward(coins: float, nature: float, xp: float, counted_min: float) -> Dictionary:
	return {"coins": _floor(coins), "nature": _floor(nature), "xp": _floor(xp), "counted_min": counted_min}


static func _floor(value: float) -> int:
	return floori(value + EPSILON)
