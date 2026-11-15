class_name StatsScreen
extends ScreenBase

const DAYS := 7
const CHART_HEIGHT := 340.0


func _build(_container: VBoxContainer) -> void:
	_add_header(UIKit.t("hud.stats"))
	if GameState.focus_sessions.is_empty() and GameState.meditation_sessions.is_empty():
		var empty := UIKit.label(UIKit.t("stats.empty"), "HeaderLabel", true)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_root.add_child(empty)
		return
	var tz: int = GameState.clock.tz_offset_seconds()
	var today: String = GameState.today()
	var first_day := DayKey.add_days(today, 1 - DAYS)
	var column := _add_scroll_body()
	_add_chart(column, today, tz)
	_add_summary(column, Stats.summary(GameState.focus_sessions, first_day, today, tz))
	_add_meditation(column, first_day, tz)


func _add_chart(column: VBoxContainer, today: String, tz: int) -> void:
	var card := UIKit.card(column)
	card.add_child(UIKit.section_title(UIKit.t("stats.last_7_days")))
	var chart := BarChart.new()
	chart.custom_minimum_size = Vector2(0, CHART_HEIGHT)
	chart.days = Stats.daily_focus_minutes(GameState.focus_sessions, today, DAYS, tz)
	card.add_child(chart)


func _add_summary(column: VBoxContainer, summary: Dictionary) -> void:
	var card := UIKit.card(column)
	card.add_child(UIKit.label(UIKit.fmt("stats.week_total", [roundi(float(summary["total_min"]))]), "HeaderLabel", true))
	card.add_child(UIKit.label(UIKit.fmt("stats.completed", [int(summary["completed"])]), "", true))
	card.add_child(UIKit.label(UIKit.fmt("stats.interrupted", [int(summary["interrupted"])]), "", true))
	var by_mode: Dictionary = summary["by_mode"]
	if by_mode.is_empty():
		return
	card.add_child(UIKit.section_title(UIKit.t("stats.by_mode")))
	for mode: String in by_mode:
		card.add_child(UIKit.label("%s: %s" % [UIKit.t("mode." + mode), UIKit.fmt("ui.minutes", [roundi(float(by_mode[mode]))])], "", true))


func _add_meditation(column: VBoxContainer, first_day: String, tz: int) -> void:
	var total := 0.0
	for offset in DAYS:
		total += Stats.meditation_minutes(GameState.meditation_sessions, DayKey.add_days(first_day, offset), tz, 0)
	var card := UIKit.card(column)
	card.add_child(UIKit.label(UIKit.fmt("stats.meditation", [roundi(total)]), "HeaderLabel", true))
