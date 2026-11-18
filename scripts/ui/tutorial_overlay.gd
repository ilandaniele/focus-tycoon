class_name TutorialOverlay
extends Control

const STEPS: Array[Dictionary] = [
	{"key": "tut.s1", "action": "next", "highlight": ""},
	{"key": "tut.s2", "action": "choice", "highlight": ""},
	{"key": "tut.s3", "action": "wait", "highlight": "build"},
	{"key": "tut.s4", "action": "wait", "highlight": "build"},
	{"key": "tut.s5", "action": "wait", "highlight": "build"},
	{"key": "tut.s6", "action": "wait", "highlight": "build"},
]
const STEP_ITEMS: Dictionary = {3: "tree_oak", 4: "enclosure_meadow"}
const TRIAL_MINUTES := 15

var _hud: Hud
var _step: int = 0
var _card: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	set_process(false)
	I18n.locale_changed.connect(_render)


func bind(hud: Hud) -> void:
	_hud = hud
	hud.open_requested.connect(_on_open_requested)
	ParkService.object_placed.connect(_on_object_placed)
	ParkService.animal_adopted.connect(_on_animal_adopted)


func start_if_needed() -> void:
	if GameState.progress.get("tutorial_done", false):
		return
	_step = clampi(int(GameState.progress.get("tutorial_step", 0)), 0, STEPS.size() - 1)
	visible = true
	_render()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var target := _highlight_target()
	if target == null:
		return
	var rect := target.get_global_rect().grow(8.0)
	rect.position -= global_position
	var pulse := 0.55 + 0.45 * sin(Time.get_ticks_msec() / 250.0)
	draw_rect(rect, Color(ThemeFactory.CORAL, pulse), false, 6.0)


func _highlight_target() -> Control:
	if _hud == null or not visible or not _hud.visible:
		return null
	var id: String = STEPS[_step]["highlight"]
	var target: Control = _hud.button_for(id) if id != "" else null
	return target if target != null and target.is_visible_in_tree() else null


func _render() -> void:
	if not visible:
		return
	if _card != null:
		_card.queue_free()
	_card = PanelContainer.new()
	_card.theme_type_variation = "CardPanel"
	_card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE, Control.PRESET_MODE_MINSIZE, 24)
	_card.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_card.offset_bottom = -200.0
	add_child(_card)
	var body := UIKit.vbox(10)
	_card.add_child(body)
	body.add_child(UIKit.label(UIKit.fmt("tut.step", [_step + 1, STEPS.size()]), "MutedLabel"))
	body.add_child(UIKit.label(UIKit.t(STEPS[_step]["key"]), "", true))
	_add_actions(body, STEPS[_step]["action"])
	body.add_child(UIKit.button(UIKit.t("tut.skip"), _finish))
	set_process(_highlight_target() != null)


func _add_actions(body: VBoxContainer, action: String) -> void:
	match action:
		"next":
			body.add_child(UIKit.primary_button(UIKit.t("ui.continue"), _set_step.bind(_step + 1)))
		"choice":
			body.add_child(UIKit.primary_button(UIKit.t("tut.try_15"), _choose.bind(true)))
			body.add_child(UIKit.secondary_button(UIKit.t("tut.explore"), _choose.bind(false)))


func _choose(try_focus: bool) -> void:
	_grant_starter()
	if try_focus:
		GameState.set_setting("default_minutes", TRIAL_MINUTES)
	_set_step(_step + 1)


func _grant_starter() -> void:
	Economy.grant("starter_grant", Config.economy["starter_grant"], "tutorial")


func _set_step(step: int) -> void:
	if step >= STEPS.size():
		_finish()
		return
	_step = step
	GameState.progress["tutorial_step"] = step
	GameState.mark_dirty()
	_render()


func _finish() -> void:
	_grant_starter()
	GameState.progress["tutorial_done"] = true
	GameState.mark_dirty()
	visible = false
	set_process(false)


func _on_open_requested(screen_name: String) -> void:
	if visible and _step == 2 and screen_name == "build":
		_set_step(3)


func _on_object_placed(uid: String) -> void:
	var item_id: String = GameState.park.objects.get(uid, {}).get("item_id", "")
	if visible and STEP_ITEMS.get(_step, "") == item_id:
		_set_step(_step + 1)


func _on_animal_adopted(_uid: String) -> void:
	if visible and _step == STEPS.size() - 1:
		_finish()
		UIKit.toast(self, UIKit.t("tut.done"))
