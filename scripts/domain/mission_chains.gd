class_name MissionChains
extends RefCounted


static func current(chain: Dictionary, claimed_steps: int, totals: Dictionary) -> Dictionary:
	var steps: Array = chain["steps"]
	var entry: Dictionary = {"id": chain["id"], "step": claimed_steps, "steps": steps.size(), "finished": claimed_steps >= steps.size()}
	if entry["finished"]:
		return entry
	var step: Dictionary = steps[claimed_steps]
	entry.merge(step)
	entry.merge(DailyObjectives.progress(step, totals))
	return entry
