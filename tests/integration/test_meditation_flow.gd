extends TestCase

var clock: FakeClock


func before_each() -> void:
	MeditationService.finish(false)
	clock = FakeClock.new()
	GameState.reset_for_tests("user://test_meditation_flow/", clock)


func test_completed_two_minute_exercise_rewards() -> void:
	assert_true(MeditationService.start("box", 2)["ok"])
	assert_eq(MeditationService.start("box", 2)["error"], "session_active")
	clock.advance(120)
	var result := MeditationService.finish(true)
	assert_true(result["ok"])
	assert_eq(result["reward"]["coins"], 2)
	assert_eq(result["reward"]["nature"], 4)
	assert_eq(result["reward"]["xp"], 2)
	assert_eq(GameState.meditation_sessions.size(), 1)
	assert_eq(GameState.meditation_sessions[0]["status"], "completed")
	assert_eq(Economy.balance("nature"), 4)
	assert_false(MeditationService.finish(true)["ok"])


func test_interrupted_under_minimum_is_recorded_without_reward() -> void:
	MeditationService.start("coherent", 5)
	clock.advance(30)
	var result := MeditationService.finish(false)
	assert_eq(result["reward"]["coins"], 0)
	assert_eq(GameState.meditation_sessions[0]["seconds"], 30)
	assert_eq(GameState.meditation_sessions[0]["status"], "interrupted")
	assert_eq(Economy.balance("nature"), 0)


func test_interrupted_after_minimum_credits_elapsed_time() -> void:
	MeditationService.start("coherent", 5)
	clock.advance(150)
	var result := MeditationService.finish(false)
	assert_eq(GameState.meditation_sessions[0]["seconds"], 150)
	assert_eq(result["reward"]["nature"], 5)


func test_daily_cap_of_sixty_minutes() -> void:
	for index in 7:
		MeditationService.start("coherent", 10)
		clock.advance(600)
		MeditationService.finish(true)
	assert_eq(Economy.balance("nature"), 120)
	assert_eq(GameState.meditation_sessions.size(), 7)


func test_unknown_exercise_rejected() -> void:
	assert_eq(MeditationService.start("nope", 1)["error"], "invalid_exercise")


func test_breath_phases() -> void:
	MeditationService.start("box", 1)
	assert_eq(MeditationService.phase_at(0)["name"], "inhale")
	assert_eq(MeditationService.phase_at(3)["name"], "inhale")
	assert_eq(MeditationService.phase_at(4)["name"], "hold")
	assert_eq(MeditationService.phase_at(8)["name"], "exhale")
	assert_eq(MeditationService.phase_at(12)["index"], 3)
	assert_eq(MeditationService.phase_at(16)["name"], "inhale")
	assert_near(MeditationService.phase_at(2)["progress"], 0.5)
	MeditationService.finish(false)
	assert_true(MeditationService.phase_at(0).is_empty())


func test_guided_prompts_cycle() -> void:
	MeditationService.start("mindful", 3)
	assert_eq(MeditationService.phase_at(0)["prompt"], "med.mindful.p1")
	assert_eq(MeditationService.phase_at(45)["prompt"], "med.mindful.p2")
	assert_eq(MeditationService.phase_at(45 * 6)["prompt"], "med.mindful.p1")
	MeditationService.finish(false)


func test_round_breathing_expands_repeated_breaths_then_retention() -> void:
	MeditationService.start("rounds", 3)
	assert_eq(MeditationService.phase_at(0)["name"], "inhale")
	assert_eq(MeditationService.phase_at(2)["name"], "exhale")
	assert_eq(MeditationService.phase_at(3)["name"], "inhale")
	assert_eq(MeditationService.phase_at(89)["name"], "exhale")
	assert_eq(MeditationService.phase_at(90)["name"], "retain")
	assert_eq(MeditationService.phase_at(135)["name"], "inhale")
	assert_eq(MeditationService.phase_at(137)["name"], "hold")
	assert_eq(MeditationService.phase_at(152)["name"], "exhale")
	assert_eq(MeditationService.phase_at(155)["name"], "rest")
	assert_eq(MeditationService.phase_at(180)["name"], "inhale")
	MeditationService.finish(false)
