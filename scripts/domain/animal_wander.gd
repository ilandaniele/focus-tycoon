class_name AnimalWander
extends RefCounted

const MIN_FPS_RATIO := 0.45
const MAX_FPS_RATIO := 1.25


static func next_point(points: Array[Vector2], current: Vector2, max_step: float, rng: RandomNumberGenerator) -> Vector2:
	var others := points.filter(func(point: Vector2) -> bool: return point != current)
	if others.is_empty():
		return current
	var near := others.filter(func(point: Vector2) -> bool: return point.distance_to(current) <= max_step)
	if near.is_empty():
		return _nearest(others, current)
	return near[rng.randi_range(0, near.size() - 1)]


static func walk_fps(base_fps: float, speed_ratio: float) -> float:
	return base_fps * clampf(sqrt(speed_ratio), MIN_FPS_RATIO, MAX_FPS_RATIO)


static func _nearest(points: Array, current: Vector2) -> Vector2:
	var best: Vector2 = points[0]
	for point: Vector2 in points:
		if point.distance_to(current) < best.distance_to(current):
			best = point
	return best
