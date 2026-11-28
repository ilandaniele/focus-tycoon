extends TestCase


func _focus(status: String, effective_min: float, reward: Dictionary) -> Dictionary:
	return {"kind": "focus", "record": {"status": status, "effective_min": effective_min}, "reward": reward}


func test_completed_session_shows_only_positive_rewards() -> void:
	var summary := SessionSummary.build([_focus("completed", 5.0, {"coins": 12, "nature": 0, "xp": 5})])
	assert_eq(summary["title_key"], "summary.title_done")
	assert_eq(summary["minutes"], 5)
	assert_eq(summary["rewards"], {"coins": 12, "xp": 5})


func test_early_end_before_first_minute_uses_gentle_copy() -> void:
	var summary := SessionSummary.build([_focus("interrupted", 0.4, {})])
	assert_eq(summary["title_key"], "summary.title_early")
	assert_eq(summary["message_key"], "summary.msg_early")
	assert_eq(summary["minutes"], 0)
	assert_true(summary["rewards"].is_empty())


func test_partial_session_with_minutes_keeps_partial_copy() -> void:
	var summary := SessionSummary.build([_focus("interrupted", 3.0, {})])
	assert_eq(summary["title_key"], "summary.title_partial")
	assert_eq(summary["message_key"], "summary.msg_partial")
	assert_eq(summary["minutes"], 3)


func test_meditation_minutes_and_totals_add_up() -> void:
	var meditation := {"kind": "meditation", "record": {"seconds": 120}, "reward": {"nature": 1, "capped": true}}
	var summary := SessionSummary.build([_focus("completed", 5.0, {"coins": 12, "xp": 5}), meditation])
	assert_eq(summary["minutes"], 7)
	assert_eq(summary["rewards"], {"coins": 12, "nature": 1, "xp": 5})
	assert_true(summary["capped"])
