extends TestCase


func before_each() -> void:
	GameState.reset_for_tests("user://test_benchmark_flow/", FakeClock.new())


func test_benchmark_replaces_park_without_touching_save() -> void:
	Economy.grant("test:fund", {"coins": 100}, "test")
	assert_true(ParkService.buy_and_place("path_dirt", Vector2i(15, 15))["ok"])
	var saved_park := GameState.park.to_dict()
	GameState.start_benchmark()
	assert_true(GameState.benchmark_active)
	assert_eq(GameState.park.objects.size(), BenchmarkPark.OBJECT_COUNT)
	GameState.save_now()
	GameState.load_or_new()
	assert_false(GameState.benchmark_active)
	assert_eq(GameState.park.to_dict(), saved_park)
