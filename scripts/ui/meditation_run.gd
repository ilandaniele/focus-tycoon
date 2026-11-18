class_name MeditationRun
extends VBoxContainer

signal finished

const CIRCLE_SIZE := 480.0

var is_done: bool = false
var _exercise_id: String
var _total_s: int
var _started_ms: int = 0
var _last_phase: String = ""
var _amount: float = 0.0
var _warning: String = ""
var _circle: BreathingCircle
var _phase: Label
var _prompt: Label
var _countdown: Label


func _init(exercise_id: String, minutes: int) -> void:
	_exercise_id = exercise_id
	_total_s = minutes * 60


func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 18)
	add_child(UIKit.label(UIKit.t("med.%s.name" % _exercise_id), "TitleLabel"))
	_circle = BreathingCircle.new()
	_circle.custom_minimum_size = Vector2(CIRCLE_SIZE, CIRCLE_SIZE)
	_circle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(_circle)
	_phase = _centered("TitleLabel")
	_prompt = _centered("MutedLabel")
	_countdown = _centered("HeaderLabel")
	add_child(UIKit.spacer())
	add_child(UIKit.button(UIKit.t("med.finish"), _finish_early))
	var warning_key: String = Config.meditations[_exercise_id].get("warning", "")
	_warning = UIKit.t(warning_key) if warning_key != "" else ""
	AudioService.play_ambient(GameState.settings.get("meditation_ambient_id", "none"))
	AudioService.play_sfx("bell")
	_started_ms = Time.get_ticks_msec()
	_update()


func _process(_delta: float) -> void:
	_update()
	if _elapsed_s() >= _total_s:
		_complete()


func _elapsed_s() -> float:
	return (Time.get_ticks_msec() - _started_ms) / 1000.0


func _update() -> void:
	var elapsed := _elapsed_s()
	var step: Dictionary = MeditationService.phase_at(int(elapsed))
	var phase_name: String = step.get("name", "")
	_advance_amount(phase_name, _smooth_progress(step, elapsed), elapsed)
	_circle.amount = _amount
	_phase.text = UIKit.t("med.phase." + phase_name) if phase_name not in ["", "prompt"] else ""
	_prompt.text = UIKit.t(step["prompt"]) if step.get("prompt", "") != "" else _warning
	_countdown.text = UIKit.mmss(ceili(_total_s - elapsed))
	if phase_name != _last_phase:
		_last_phase = phase_name
		Platform.haptic(30)
		_play_cue(phase_name)


func _play_cue(phase_name: String) -> void:
	var cue := AudioSynth.cue_for(phase_name)
	if cue != "":
		AudioService.play_sfx(cue)


func _smooth_progress(step: Dictionary, elapsed: float) -> float:
	var seconds := float(step.get("seconds", 0))
	if seconds <= 0.0:
		return float(step.get("progress", 0.0))
	return (float(step.get("elapsed", 0)) + elapsed - floorf(elapsed)) / seconds


func _advance_amount(phase_name: String, progress: float, elapsed: float) -> void:
	match phase_name:
		"inhale":
			_amount = progress
		"exhale":
			_amount = 1.0 - progress
		"hold", "retain":
			pass
		_:
			_amount = 0.5 + 0.5 * sin(elapsed * TAU / 8.0)


func _centered(variation: String) -> Label:
	var label := UIKit.label("", variation, true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
	return label


func _finish_early() -> void:
	_end(false)


func _complete() -> void:
	_end(true)


func _end(completed: bool) -> void:
	_record(completed)
	AudioService.play_sfx("bell")
	finished.emit()


func _record(completed: bool) -> void:
	is_done = true
	set_process(false)
	AudioService.stop_ambient()
	MeditationService.finish(completed)


func _exit_tree() -> void:
	if not is_done:
		_record(false)
