extends TestCase

const STEP := 100.0


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	return rng


func _row(count: int) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for index in count:
		points.append(Vector2(index * 64.0, 0.0))
	return points


func test_next_point_stays_within_step() -> void:
	var points := _row(10)
	var rng := _rng()
	for _i in 50:
		var target := AnimalWander.next_point(points, Vector2.ZERO, STEP, rng)
		assert_true(target != Vector2.ZERO, "never stays in place")
		assert_true(target.distance_to(Vector2.ZERO) <= STEP, "short hop only")


func test_next_point_falls_back_to_nearest_when_isolated() -> void:
	var points: Array[Vector2] = [Vector2.ZERO, Vector2(500, 0), Vector2(900, 0)]
	assert_eq(AnimalWander.next_point(points, Vector2.ZERO, STEP, _rng()), Vector2(500, 0))


func test_next_point_with_single_point_stays() -> void:
	var points: Array[Vector2] = [Vector2(10, 10)]
	assert_eq(AnimalWander.next_point(points, Vector2(10, 10), STEP, _rng()), Vector2(10, 10))


func test_walk_fps_follows_speed() -> void:
	assert_eq(AnimalWander.walk_fps(10.0, 1.0), 10.0)
	assert_true(AnimalWander.walk_fps(10.0, 0.3) < 10.0, "slow species step slower")
	assert_true(AnimalWander.walk_fps(10.0, 0.05) >= 10.0 * AnimalWander.MIN_FPS_RATIO, "clamped low")
	assert_true(AnimalWander.walk_fps(10.0, 5.0) <= 10.0 * AnimalWander.MAX_FPS_RATIO, "clamped high")
