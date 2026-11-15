class_name FocusSetup
extends VBoxContainer

signal start_requested(plan: Dictionary)

const AMBIENTS: Array[String] = ["none", "rain", "forest", "brown"]

var _minutes: int = 25
var _mode: String = "study"
var _cycles: int = 1
var _break_min: int = 5
var _ambient: String = "none"
var _presets: ChipGroup
var _minutes_label: Label
var _break_card: VBoxContainer
var _focus_cfg: Dictionary = Config.economy["focus"]


func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 16)
	_load_defaults()
	var scroll := UIKit.scroll_body(self)
	var column := UIKit.vbox(16)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	_build_duration(UIKit.card(column))
	_build_choice(column, "focus.mode", _mode_options(), _mode, _set_mode)
	_build_choice(column, "focus.cycles", _numbered(1, _focus_cfg["max_cycles"]), _cycles, _set_cycles)
	_break_card = _build_choice(column, "focus.break", _break_options(), _break_min, _set_break)
	_break_card.get_parent().visible = _cycles > 1
	_build_choice(column, "focus.ambient", _ambient_options(), _ambient, _set_ambient)
	add_child(UIKit.primary_button(UIKit.t("focus.start"), _on_start))


func _load_defaults() -> void:
	var settings: Dictionary = GameState.settings
	_minutes = settings.get("default_minutes", 25)
	_mode = settings.get("default_mode", "study")
	_cycles = settings.get("cycles", 1)
	_break_min = settings.get("break_min", 5)
	_ambient = settings.get("ambient_id", "none")


func _build_duration(card: VBoxContainer) -> void:
	card.add_child(UIKit.section_title(UIKit.t("focus.duration")))
	var options: Array = []
	for minutes: int in _focus_cfg["presets"]:
		options.append({"id": minutes, "text": UIKit.fmt("ui.minutes", [minutes])})
	_presets = UIKit.chips(options, _minutes, _set_minutes)
	card.add_child(_presets)
	var stepper := UIKit.hbox(12)
	stepper.add_child(UIKit.button("-5", _step.bind(-5)))
	_minutes_label = UIKit.label("", "HeaderLabel")
	_minutes_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minutes_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stepper.add_child(_minutes_label)
	stepper.add_child(UIKit.button("+5", _step.bind(5)))
	card.add_child(stepper)
	_refresh_minutes()


func _build_choice(parent: Node, title_key: String, options: Array, initial: Variant, on_select: Callable) -> VBoxContainer:
	var card := UIKit.card(parent)
	card.add_child(UIKit.section_title(UIKit.t(title_key)))
	card.add_child(UIKit.chips(options, initial, on_select))
	return card


func _mode_options() -> Array:
	var options: Array = []
	for mode: String in Config.economy["modes"]:
		options.append({"id": mode, "text": UIKit.t("mode." + mode)})
	return options


func _break_options() -> Array:
	var options: Array = []
	for minutes: int in _focus_cfg["break_options"]:
		options.append({"id": minutes, "text": UIKit.fmt("ui.minutes", [minutes])})
	return options


func _ambient_options() -> Array:
	var options: Array = []
	for id in AMBIENTS:
		options.append({"id": id, "text": UIKit.t("focus.ambient." + id)})
	return options


func _numbered(first: int, last: int) -> Array:
	var options: Array = []
	for value in range(first, last + 1):
		options.append({"id": value, "text": str(value)})
	return options


func _refresh_minutes() -> void:
	_minutes_label.text = UIKit.fmt("ui.minutes", [_minutes])
	_presets.select(_minutes)


func _set_minutes(minutes: int) -> void:
	_minutes = minutes
	_refresh_minutes()


func _step(delta: int) -> void:
	_set_minutes(clampi(_minutes + delta, _focus_cfg["min_minutes"], _focus_cfg["max_minutes"]))


func _set_mode(mode: String) -> void:
	_mode = mode


func _set_cycles(cycles: int) -> void:
	_cycles = cycles
	_break_card.get_parent().visible = cycles > 1


func _set_break(minutes: int) -> void:
	_break_min = minutes


func _set_ambient(id: String) -> void:
	_ambient = id


func _on_start() -> void:
	GameState.set_setting("default_minutes", _minutes)
	GameState.set_setting("default_mode", _mode)
	GameState.set_setting("cycles", _cycles)
	GameState.set_setting("break_min", _break_min)
	GameState.set_setting("ambient_id", _ambient)
	var plan := {"minutes": _minutes, "mode": _mode, "cycles": _cycles, "break_min": _break_min if _cycles > 1 else 0}
	start_requested.emit(plan)
