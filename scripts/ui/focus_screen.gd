class_name FocusScreen
extends ScreenBase


func _ready() -> void:
	super()
	FocusService.focus_finished.connect(_on_focus_finished)
	FocusService.started.connect(_rebuild)


func _build(_container: VBoxContainer) -> void:
	set_tint(ThemeFactory.SAND)
	_add_header(UIKit.t("hud.focus"))
	if FocusService.is_active():
		_add_run()
	else:
		_add_setup()


func _add_setup() -> void:
	var setup := FocusSetup.new()
	setup.start_requested.connect(_on_start_requested)
	_root.add_child(setup)


func _add_run() -> void:
	var run := FocusRun.new()
	run.tint_requested.connect(set_tint)
	_root.add_child(run)


func _on_start_requested(plan: Dictionary) -> void:
	var result: Dictionary = FocusService.start(plan["minutes"], plan["mode"], plan["cycles"], plan["break_min"])
	if not result.get("ok", false):
		UIKit.toast_error(self, result.get("error", "session_active"))
		_rebuild()
		return
	AudioService.play_ambient(GameState.settings.get("ambient_id", "none"))


func _on_focus_finished(_record: Dictionary, _reward: Dictionary) -> void:
	_close_if_idle.call_deferred()


func _close_if_idle() -> void:
	if not FocusService.is_active():
		close_requested.emit()
