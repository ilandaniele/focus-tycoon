extends Node

const SCREEN_SCENES := {
	"focus": "res://scenes/ui/focus_screen.tscn",
	"meditation": "res://scenes/ui/meditation_screen.tscn",
	"build": "res://scenes/ui/build_catalog.tscn",
	"stats": "res://scenes/ui/stats_screen.tscn",
	"profile": "res://scenes/ui/profile_screen.tscn",
}
const FULLSCREEN_MAX_FPS := 30

@onready var _world: Variant = $ParkWorld
@onready var _hud: Hud = $UI/HUD
@onready var _host: Control = $UI/ScreenHost
@onready var _tutorial: TutorialOverlay = $UI/TutorialOverlay
@onready var _toasts: Toasts = $UI/Toasts
@onready var _dialogs: Control = $UI/Dialogs

var _screen: ScreenBase
var _sheet: ObjectSheet
var _summary_buffer: Array[Dictionary] = []
var _modal_queue: Array[Callable] = []
var _modal_open: bool = false
var _saved_max_fps: int = 0


func _ready() -> void:
	_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_theme()
	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)
	GameState.settings_changed.connect(_on_setting_changed)
	_hud.bind_world(_world)
	_hud.open_requested.connect(open_screen)
	_tutorial.bind(_hud)
	_world.object_tapped.connect(_on_object_tapped)
	_world.adopt_resolved.connect(_on_adopt_resolved)
	Economy.level_up.connect(_on_level_up)
	Economy.achievement_earned.connect(_on_achievement)
	FocusService.focus_finished.connect(_on_focus_finished)
	FocusService.phase_changed.connect(_on_phase_changed)
	MeditationService.finished.connect(_on_meditation_finished)
	_collect_pending_summaries()
	_resume_ambient()
	_tutorial.start_if_needed()


func open_screen(screen_name: String) -> void:
	close_screen()
	_dismiss_sheet()
	var scene: PackedScene = load(SCREEN_SCENES[screen_name])
	_screen = scene.instantiate()
	_screen.close_requested.connect(close_screen)
	if screen_name == "build":
		_screen.connect("placement_requested", _begin_placement)
		_screen.connect("adopt_requested", _begin_adopt)
	_host.add_child(_screen)
	UIKit.fade_in(_screen)
	_set_fullscreen_mode(true)


func close_screen() -> void:
	if _screen == null:
		return
	_host.remove_child(_screen)
	_screen.queue_free()
	_screen = null
	_set_fullscreen_mode(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _screen != null:
		close_screen()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		close_screen()


func _set_fullscreen_mode(open: bool) -> void:
	_world.set_active(not open)
	_hud.visible = not open
	OS.low_processor_usage_mode = open
	if open:
		_saved_max_fps = Engine.max_fps
		Engine.max_fps = FULLSCREEN_MAX_FPS
	else:
		Engine.max_fps = _saved_max_fps


func _apply_theme() -> void:
	var theme := ThemeFactory.build()
	for root: Control in [_hud, _host, _tutorial, _toasts, _dialogs]:
		root.theme = theme


func _apply_safe_area() -> void:
	for root: Control in [_hud, _tutorial, _toasts]:
		SafeArea.inset_full_rect(root)


func _on_setting_changed(key: String) -> void:
	if key == "text_scale":
		_apply_theme()


func _begin_placement(item_id: String) -> void:
	close_screen()
	_world.begin_placement(item_id)


func _begin_adopt(species_id: String) -> void:
	close_screen()
	_world.begin_adopt_target(species_id)


func _on_adopt_resolved(result: Dictionary) -> void:
	if not result.get("ok", false):
		UIKit.toast_error(self, str(result.get("error", "")))


func _on_object_tapped(uid: String) -> void:
	_dismiss_sheet()
	_sheet = ObjectSheet.open(_host, _world, uid)


func _dismiss_sheet() -> void:
	if is_instance_valid(_sheet):
		_sheet.queue_free()
	_sheet = null


func _on_achievement(id: String) -> void:
	_toasts.push(UIKit.fmt("hud.achievement", [tr("ach." + id)]))


func _on_level_up(level: int, unlocked: Array) -> void:
	_enqueue_modal(LevelUpDialog.show_card.bind(_dialogs, level, unlocked))


func _on_focus_finished(record: Dictionary, reward: Dictionary) -> void:
	_summary_buffer.append({"kind": "focus", "record": record, "reward": reward})
	_flush_summaries.call_deferred()


func _on_phase_changed(_state: int) -> void:
	_flush_summaries.call_deferred()


func _on_meditation_finished(record: Dictionary, reward: Dictionary) -> void:
	_summary_buffer.append({"kind": "meditation", "record": record, "reward": reward})
	_flush_summaries.call_deferred()


func _collect_pending_summaries() -> void:
	for summary: Dictionary in FocusService.take_pending_summaries():
		_summary_buffer.append({"kind": "focus", "record": summary["record"], "reward": summary["reward"]})
	_flush_summaries.call_deferred()


func _flush_summaries() -> void:
	if _summary_buffer.is_empty() or FocusService.is_active():
		return
	var entries := _summary_buffer.duplicate()
	_summary_buffer.clear()
	AudioService.stop_ambient()
	AudioService.play_sfx("bell")
	_enqueue_modal(SummaryDialog.show_entries.bind(_dialogs, entries))


func _resume_ambient() -> void:
	var ambient: String = GameState.settings.get("ambient_id", "none")
	if FocusService.is_active() and ambient != "none":
		AudioService.play_ambient(ambient)


func _enqueue_modal(builder: Callable) -> void:
	_modal_queue.append(builder)
	_pump_modals()


func _pump_modals() -> void:
	if _modal_open or _modal_queue.is_empty():
		return
	_modal_open = true
	var dialog: ModalDialog = _modal_queue.pop_front().call()
	dialog.closed.connect(_on_modal_closed)


func _on_modal_closed() -> void:
	_modal_open = false
	_pump_modals.call_deferred()
