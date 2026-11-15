extends TestCase

var clock: FakeClock


func before_each() -> void:
	clock = FakeClock.new()
	GameState.reset_for_tests("user://test_focus_flow/", clock)


func _past_session(minutes: float, ended_at: int) -> Dictionary:
	return {"id": "old#%d" % ended_at, "mode": "study", "planned_min": int(minutes), "effective_min": minutes,
		"status": "completed", "started_at": ended_at - int(minutes * 60), "ended_at": ended_at, "cycle": 1}


func test_session_finished_in_background_is_rewarded_exactly_once() -> void:
	assert_true(FocusService.start(25, "study")["ok"])
	assert_true(FocusService.is_active())
	assert_eq(FocusService.start(25, "study")["error"], "session_active")
	clock.advance(30 * 60)
	FocusService.tick_now()
	FocusService.tick_now()
	assert_eq(GameState.focus_sessions.size(), 1)
	assert_eq(Economy.balance("coins"), 60 + 20)
	assert_eq(Economy.balance("nature"), 2)
	assert_eq(Economy.balance("xp"), 25)
	assert_true(GameState.ledger.has_key("focus:s_1#1"))
	assert_false(FocusService.is_active())
	var summaries := FocusService.take_pending_summaries()
	assert_eq(summaries.size(), 1)
	assert_eq(summaries[0]["reward"]["coins"], 60)
	assert_eq(summaries[0]["record"]["ended_at"], clock.t - 5 * 60)
	assert_true(FocusService.take_pending_summaries().is_empty())

	GameState.load_or_new()
	FocusService.tick_now()
	assert_eq(GameState.focus_sessions.size(), 1)
	assert_eq(Economy.balance("coins"), 80)
	assert_false(FocusService.is_active())


func test_app_closed_mid_session_resumes_and_completes_after_reload() -> void:
	FocusService.start(25, "work")
	clock.advance(10 * 60)
	FocusService.tick_now()
	GameState.save_now()
	GameState.load_or_new()
	assert_true(FocusService.is_active())
	assert_eq(FocusService.remaining_s(), 15 * 60)
	clock.advance(20 * 60)
	FocusService.tick_now()
	assert_eq(GameState.focus_sessions.size(), 1)
	assert_eq(GameState.focus_sessions[0]["mode"], "work")
	assert_eq(Economy.balance("xp"), 25)


func test_three_cycles_finished_while_away_credit_each_cycle_in_order() -> void:
	FocusService.start(25, "study", 3, 5)
	clock.advance(100 * 60)
	FocusService.tick_now()
	FocusService.tick_now()
	var ids: Array = GameState.focus_sessions.map(func(record: Dictionary) -> String: return record["id"])
	assert_eq(ids, ["s_1#1", "s_1#2", "s_1#3"])
	assert_eq(Economy.balance("coins"), 3 * 60 + 20)
	assert_eq(Economy.balance("xp"), 75)
	assert_eq(FocusService.state(), FocusTimer.State.FINISHED)
	assert_eq(FocusService.take_pending_summaries().size(), 3)


func test_interrupt_rewards_half_without_bonus() -> void:
	FocusService.start(25, "study")
	clock.advance(10 * 60)
	FocusService.interrupt()
	assert_false(FocusService.is_active())
	assert_eq(GameState.focus_sessions[0]["status"], "interrupted")
	assert_eq(Economy.balance("coins"), 10)
	assert_eq(Economy.balance("xp"), 5)


func test_interrupt_under_five_minutes_is_recorded_without_reward() -> void:
	FocusService.start(25, "study")
	clock.advance(3 * 60)
	FocusService.interrupt()
	assert_eq(GameState.focus_sessions.size(), 1)
	assert_eq(Economy.balance("coins"), 0)
	assert_eq(Economy.balance("xp"), 0)


func test_pause_resume_through_service() -> void:
	FocusService.start(25, "study")
	clock.advance(10 * 60)
	FocusService.pause()
	clock.advance(60 * 60)
	FocusService.tick_now()
	assert_true(FocusService.is_active())
	assert_eq(FocusService.remaining_s(), 15 * 60)
	FocusService.resume()
	clock.advance(15 * 60)
	FocusService.tick_now()
	assert_eq(GameState.focus_sessions.size(), 1)
	assert_near(GameState.focus_sessions[0]["effective_min"], 25.0)


func test_start_rejects_out_of_range_minutes() -> void:
	assert_eq(FocusService.start(4, "study")["error"], "invalid_minutes")
	assert_eq(FocusService.start(181, "study")["error"], "invalid_minutes")
	assert_false(FocusService.is_active())


func test_clock_set_back_closes_session_as_interrupted_at_last_seen() -> void:
	FocusService.start(25, "study")
	var started := clock.t
	clock.advance(10 * 60)
	FocusService.tick_now()
	clock.advance(-3600)
	FocusService.tick_now()
	assert_false(FocusService.is_active())
	var record: Dictionary = GameState.focus_sessions[0]
	assert_eq(record["status"], "interrupted")
	assert_eq(record["ended_at"], started + 10 * 60)
	assert_eq(Economy.balance("coins"), 10)


func test_daily_cap_applies_across_sessions_of_the_same_day() -> void:
	GameState.focus_sessions.append(_past_session(480.0, clock.t - 3600))
	FocusService.start(30, "study")
	clock.advance(30 * 60)
	FocusService.tick_now()
	assert_eq(GameState.focus_sessions.size(), 2)
	assert_eq(Economy.balance("coins"), 20)
	assert_eq(Economy.balance("xp"), 0)


func test_cap_splits_a_session_that_crosses_the_threshold() -> void:
	GameState.focus_sessions.append(_past_session(230.0, clock.t - 3600))
	FocusService.start(20, "study")
	clock.advance(20 * 60)
	FocusService.tick_now()
	assert_eq(Economy.balance("xp"), 15)
	assert_eq(Economy.balance("coins"), 36 + 20)


func test_first_session_achievement_granted_once() -> void:
	FocusService.start(25, "study")
	clock.advance(25 * 60)
	FocusService.tick_now()
	assert_true(GameState.progress["achievements"].has("first_session"))
	FocusService.start(25, "study")
	clock.advance(25 * 60)
	FocusService.tick_now()
	assert_eq(Economy.balance("coins"), 60 + 60 + 20)


func test_state_loaded_reconciles_session_that_ended_while_closed() -> void:
	FocusService.start(25, "study")
	GameState.save_now()
	clock.advance(2 * 3600)
	GameState.load_or_new()
	FocusService.tick_now()
	assert_eq(GameState.focus_sessions.size(), 1)
	assert_eq(Economy.balance("coins"), 80)
