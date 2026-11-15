extends TestCase

const T0 := 1_000_000


func _started(minutes: int = 25, cycles: int = 1, break_min: int = 0) -> FocusTimer:
	var timer := FocusTimer.new()
	timer.start(T0, "s_1", minutes, "study", cycles, break_min)
	return timer


func _types(events: Array) -> Array:
	return events.map(func(event: Dictionary) -> String: return event["type"])


func _roundtrip(timer: FocusTimer) -> FocusTimer:
	return FocusTimer.from_dict(JSON.parse_string(JSON.stringify(timer.to_dict())))


func test_completes_exactly_at_planned_end() -> void:
	var timer := _started()
	assert_true(timer.tick(T0 + 1499).is_empty())
	var events := timer.tick(T0 + 1500)
	assert_eq(_types(events), ["focus_completed", "plan_finished"])
	var record: Dictionary = events[0]["record"]
	assert_eq(record["id"], "s_1#1")
	assert_eq(record["status"], "completed")
	assert_eq(record["ended_at"], T0 + 1500)
	assert_eq(record["started_at"], T0)
	assert_near(record["effective_min"], 25.0)
	assert_eq(timer.state, FocusTimer.State.FINISHED)


func test_pause_time_is_excluded() -> void:
	var timer := _started()
	timer.pause(T0 + 600)
	assert_eq(timer.elapsed_focus_s(T0 + 1200), 600)
	assert_true(timer.tick(T0 + 5000).is_empty())
	timer.resume(T0 + 5300)
	assert_eq(timer.remaining_s(T0 + 5300), 900)
	assert_true(timer.tick(T0 + 6199).is_empty())
	var events := timer.tick(T0 + 6200)
	assert_eq(events[0]["record"]["ended_at"], T0 + 6200)
	assert_near(events[0]["record"]["effective_min"], 25.0)


func test_backgrounded_past_end_completes_with_exact_ended_at() -> void:
	var timer := _started()
	var events := timer.tick(T0 + 9999)
	assert_eq(events[0]["record"]["ended_at"], T0 + 1500)
	assert_true(timer.tick(T0 + 20000).is_empty())


func test_three_cycles_with_breaks_all_elapsed_while_away() -> void:
	var timer := _started(25, 3, 5)
	var events := timer.tick(T0 + 100 * 60)
	assert_eq(_types(events), ["focus_completed", "break_started", "break_completed", "focus_completed",
		"break_started", "break_completed", "focus_completed", "plan_finished"])
	var records := events.filter(func(event: Dictionary) -> bool: return event["type"] == "focus_completed").map(
		func(event: Dictionary) -> Dictionary: return event["record"])
	assert_eq(records.map(func(record: Dictionary) -> String: return record["id"]), ["s_1#1", "s_1#2", "s_1#3"])
	assert_eq(records.map(func(record: Dictionary) -> int: return record["started_at"]), [T0, T0 + 1800, T0 + 3600])
	assert_eq(records[2]["ended_at"], T0 + 5100)
	assert_eq(timer.state, FocusTimer.State.FINISHED)


func test_cycles_without_break_chain_directly() -> void:
	var timer := _started(10, 2, 0)
	var events := timer.tick(T0 + 1200)
	assert_eq(_types(events), ["focus_completed", "focus_completed", "plan_finished"])
	assert_eq(events[1]["record"]["started_at"], T0 + 600)


func test_break_state_and_skip() -> void:
	var timer := _started(25, 2, 5)
	assert_eq(_types(timer.tick(T0 + 1500)), ["focus_completed", "break_started"])
	assert_eq(timer.state, FocusTimer.State.BREAK)
	assert_eq(timer.remaining_s(T0 + 1560), 240)
	timer.skip_break(T0 + 1560)
	assert_eq(timer.state, FocusTimer.State.FOCUS)
	assert_eq(timer.remaining_s(T0 + 1560), 1500)
	var events := timer.tick(T0 + 1560 + 1500)
	assert_eq(events[0]["record"]["started_at"], T0 + 1560)


func test_clock_going_back_beyond_120s_interrupts_at_last_seen() -> void:
	var timer := _started()
	timer.tick(T0 + 600)
	var events := timer.tick(T0 + 100)
	assert_eq(_types(events), ["clock_anomaly"])
	var record: Dictionary = events[0]["record"]
	assert_eq(record["status"], "interrupted")
	assert_eq(record["ended_at"], T0 + 600)
	assert_near(record["effective_min"], 10.0)
	assert_eq(timer.state, FocusTimer.State.IDLE)


func test_small_backwards_jump_is_tolerated() -> void:
	var timer := _started()
	timer.tick(T0 + 600)
	assert_true(timer.tick(T0 + 540).is_empty())
	assert_eq(timer.state, FocusTimer.State.FOCUS)


func test_interrupt_records_effective_time() -> void:
	var timer := _started()
	var record := timer.interrupt(T0 + 600)
	assert_eq(record["status"], "interrupted")
	assert_near(record["effective_min"], 10.0)
	assert_eq(record["ended_at"], T0 + 600)
	assert_eq(timer.state, FocusTimer.State.IDLE)
	assert_true(timer.interrupt(T0 + 700).is_empty())


func test_interrupt_while_paused_excludes_paused_time() -> void:
	var timer := _started()
	timer.pause(T0 + 300)
	var record := timer.interrupt(T0 + 900)
	assert_near(record["effective_min"], 5.0)


func test_to_dict_roundtrip_mid_session() -> void:
	var timer := _started(25, 2, 5)
	timer.pause(T0 + 300)
	timer.resume(T0 + 400)
	timer.tick(T0 + 500)
	var restored := _roundtrip(timer)
	assert_eq(restored.state, FocusTimer.State.FOCUS)
	assert_eq(restored.remaining_s(T0 + 700), timer.remaining_s(T0 + 700))
	var original_events := timer.tick(T0 + 4000)
	var restored_events := restored.tick(T0 + 4000)
	assert_eq(JSON.stringify(restored_events), JSON.stringify(original_events))
	assert_eq(restored.to_dict()["cycle"], timer.to_dict()["cycle"])


func test_roundtrip_while_paused() -> void:
	var timer := _started()
	timer.pause(T0 + 300)
	var restored := _roundtrip(timer)
	assert_eq(restored.state, FocusTimer.State.PAUSED)
	assert_eq(restored.elapsed_focus_s(T0 + 9999), 300)
