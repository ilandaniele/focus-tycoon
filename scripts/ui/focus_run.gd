class_name FocusRun
extends VBoxContainer

signal tint_requested(color: Color)

const RING_SIZE := 460.0

var _ring: ProgressRing
var _time: Label
var _mode: Label
var _cycle: Label
var _pause: Button
var _skip: Button
var _end: Button


func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 18)
	_mode = UIKit.label("", "TitleLabel")
	_cycle = UIKit.label("", "MutedLabel")
	for label: Label in [_mode, _cycle]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
	_ring = ProgressRing.new()
	_ring.custom_minimum_size = Vector2(RING_SIZE, RING_SIZE)
	_ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(_ring)
	_time = UIKit.label("", "BigLabel")
	_time.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_time.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ring.add_child(_time)
	add_child(UIKit.spacer())
	_pause = UIKit.primary_button("", _toggle_pause)
	_skip = UIKit.secondary_button(UIKit.t("focus.skip_break"), FocusService.skip_break)
	_end = UIKit.button(UIKit.t("focus.end_now"), _confirm_end)
	for button: Button in [_pause, _skip, _end]:
		add_child(button)
	FocusService.ticked.connect(_on_ticked)
	FocusService.phase_changed.connect(_refresh)
	_refresh()


func _refresh(_state: int = 0) -> void:
	var state: int = FocusService.state()
	var in_break := state == FocusTimer.State.BREAK
	var paused := state == FocusTimer.State.PAUSED
	var plan: Dictionary = GameState.timer.to_dict()
	var cycles: int = plan.get("cycles", 1)
	_mode.text = UIKit.t("focus.break_title") if in_break else UIKit.t("mode." + str(plan.get("mode", "")))
	_cycle.text = UIKit.fmt("focus.cycle", [plan.get("cycle", 1), cycles]) if cycles > 1 else ""
	_cycle.visible = cycles > 1
	_pause.text = UIKit.t("focus.resume" if paused else "focus.pause")
	_pause.visible = not in_break
	_skip.visible = in_break
	_ring.color = ThemeFactory.MINT if in_break else ThemeFactory.CORAL
	tint_requested.emit(ThemeFactory.MINT.lightened(0.6) if in_break else ThemeFactory.SAND)
	_on_ticked(FocusService.remaining_s())


func _on_ticked(remaining_s: int) -> void:
	_time.text = UIKit.mmss(remaining_s)
	_ring.progress = 1.0 - float(remaining_s) / float(maxi(_phase_total_s(), 1))


func _phase_total_s() -> int:
	var plan: Dictionary = GameState.timer.to_dict()
	var minutes: int = plan.get("break_min" if FocusService.state() == FocusTimer.State.BREAK else "planned_min", 0)
	return minutes * 60


func _toggle_pause() -> void:
	if FocusService.state() == FocusTimer.State.PAUSED:
		FocusService.resume()
	else:
		FocusService.pause()


func _confirm_end() -> void:
	var dialog := ModalDialog.open(self, UIKit.t("focus.end_title"))
	dialog.body.add_child(UIKit.label(UIKit.t("focus.end_body"), "", true))
	dialog.add_button(UIKit.t("focus.end_confirm"), true, FocusService.interrupt)
	dialog.add_button(UIKit.t("focus.keep_going"), false)
