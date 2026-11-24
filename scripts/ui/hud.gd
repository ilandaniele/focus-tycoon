class_name Hud
extends Control

signal open_requested(screen_name: String)

const NAV_ITEMS: Array[Dictionary] = [
	{"id": "meditation", "key": "hud.meditate", "icon": "meditate"},
	{"id": "build", "key": "hud.build", "icon": "build"},
	{"id": "focus", "key": "hud.focus", "icon": "focus"},
	{"id": "stats", "key": "hud.stats", "icon": "stats"},
	{"id": "profile", "key": "hud.profile", "icon": "profile"},
]
const FOCUS_SIZE := 150.0
const NAV_HEIGHT := 104.0

var _world: Variant = null
var _coins: PanelContainer
var _nature: PanelContainer
var _level: Label
var _xp: ProgressBar
var _nav: HBoxContainer
var _placement: PlacementBar
var _buttons: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	I18n.locale_changed.connect(_build)
	Economy.resources_changed.connect(_on_resources_changed)
	Economy.level_up.connect(_on_level_up)
	FocusService.started.connect(_refresh_focus_button)
	FocusService.ticked.connect(_on_ticked)
	FocusService.phase_changed.connect(_on_phase_changed)
	FocusService.focus_finished.connect(_on_focus_finished)


func bind_world(world: Variant) -> void:
	_world = world
	world.placement_changed.connect(_on_placement_changed)


func button_for(id: String) -> Control:
	return _buttons.get(id)


func _build() -> void:
	UIKit.clear(self)
	_buttons.clear()
	var root := UIKit.vbox(0)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	root.add_child(_margined(_build_top(), 24))
	root.add_child(UIKit.spacer())
	root.add_child(_margined(_build_bottom(), 20))
	_on_resources_changed(GameState.ledger.balances)
	_refresh_focus_button()


func _build_top() -> VBoxContainer:
	var column := UIKit.vbox(10)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar := UIKit.card(column)
	var row := UIKit.hbox(10)
	bar.add_child(row)
	_coins = UIKit.resource_pill("coins", 0)
	_nature = UIKit.resource_pill("nature", 0)
	_level = UIKit.label("", "HeaderLabel")
	_level.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for node: Control in [_coins, _nature, _level]:
		row.add_child(node)
	_xp = ProgressBar.new()
	_xp.show_percentage = false
	_xp.max_value = 1.0
	_xp.step = 0.001
	_xp.custom_minimum_size = Vector2(0, 14)
	bar.add_child(_xp)
	column.add_child(ObjectivesCard.new())
	return column


func _build_bottom() -> VBoxContainer:
	var stack := UIKit.vbox(10)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_placement = PlacementBar.new()
	_placement.visible = false
	_placement.confirmed.connect(_on_confirm_placement)
	_placement.cancelled.connect(_on_cancel_placement)
	stack.add_child(_placement)
	_nav = UIKit.hbox(10)
	_nav.alignment = BoxContainer.ALIGNMENT_CENTER
	_nav.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(_nav)
	for item in NAV_ITEMS:
		_nav.add_child(_nav_button(item))
	return stack


func _nav_button(item: Dictionary) -> Button:
	var id: String = item["id"]
	var button := UIKit.button(UIKit.t(item["key"]), _on_nav_pressed.bind(id), "NavButton")
	button.icon = UIKit.icon(item["icon"])
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	if id == "focus":
		button.theme_type_variation = "FocusButton"
		button.custom_minimum_size = Vector2(FOCUS_SIZE, FOCUS_SIZE)
	else:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, NAV_HEIGHT)
		button.clip_text = true
	_buttons[id] = button
	return button


func _margined(child: Control, vertical: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, vertical)
	margin.add_child(child)
	return margin


func _on_nav_pressed(id: String) -> void:
	open_requested.emit(id)


func _on_resources_changed(balances: Dictionary) -> void:
	UIKit.set_pill_value(_coins, int(balances.get("coins", 0)))
	UIKit.set_pill_value(_nature, int(balances.get("nature", 0)))
	_level.text = UIKit.fmt("hud.level", [Economy.level()])
	_xp.value = _xp_fraction(int(balances.get("xp", 0)))


func _on_level_up(_level_reached: int, _unlocked: Array) -> void:
	_on_resources_changed(GameState.ledger.balances)


func _xp_fraction(xp: int) -> float:
	var thresholds: Array = Config.economy["levels"]["xp_thresholds"]
	var level: int = Economy.level()
	if level >= thresholds.size():
		return 1.0
	var low: int = thresholds[level - 1]
	var high: int = thresholds[level]
	return clampf(float(xp - low) / float(maxi(high - low, 1)), 0.0, 1.0)


func _refresh_focus_button() -> void:
	var button: Button = _buttons["focus"]
	button.text = UIKit.mmss(FocusService.remaining_s()) if FocusService.is_active() else UIKit.t("hud.focus")


func _on_ticked(_remaining_s: int) -> void:
	_refresh_focus_button()


func _on_phase_changed(_state: int) -> void:
	_refresh_focus_button()


func _on_focus_finished(_record: Dictionary, _reward: Dictionary) -> void:
	_refresh_focus_button()


func _on_placement_changed(active: bool, valid: bool) -> void:
	_nav.visible = not active
	_placement.visible = active
	_placement.set_valid(valid, _world.placement_hint())


func _on_confirm_placement() -> void:
	var result: Dictionary = _world.confirm_placement()
	if not result.get("ok", false):
		UIKit.toast_error(self, result.get("error", "invalid_cell"))


func _on_cancel_placement() -> void:
	_world.cancel_placement()
