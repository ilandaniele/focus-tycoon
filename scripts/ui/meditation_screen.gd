class_name MeditationScreen
extends ScreenBase

var _minutes: Dictionary = {}
var _running: bool = false


func _build(_container: VBoxContainer) -> void:
	_add_header(UIKit.t("hud.meditate"))
	if _running:
		return
	var column := _add_scroll_body()
	column.add_child(UIKit.label(UIKit.t("med.disclaimer"), "MutedLabel", true))
	for id: String in Config.meditations:
		_add_exercise_card(column, Config.meditations[id])


func _add_exercise_card(parent: Node, exercise: Dictionary) -> void:
	var id: String = exercise["id"]
	var durations: Array = exercise["durations"]
	if not _minutes.has(id):
		_minutes[id] = int(durations[0])
	var card := UIKit.card(parent)
	card.add_child(UIKit.section_title(UIKit.t("med.%s.name" % id)))
	card.add_child(UIKit.label(UIKit.t("med.%s.desc" % id), "MutedLabel", true))
	var options: Array = []
	for minutes: int in durations:
		options.append({"id": minutes, "text": UIKit.fmt("ui.minutes", [minutes])})
	card.add_child(UIKit.chips(options, _minutes[id], _set_minutes.bind(id)))
	card.add_child(UIKit.primary_button(UIKit.t("med.start"), _start.bind(id)))


func _set_minutes(minutes: int, id: String) -> void:
	_minutes[id] = minutes


func _start(id: String) -> void:
	var result: Dictionary = MeditationService.start(id, _minutes[id])
	if not result.get("ok", true):
		UIKit.toast_error(self, result.get("error", "session_active"))
		return
	_running = true
	_rebuild()
	var run := MeditationRun.new(id, _minutes[id])
	run.finished.connect(_request_close)
	_root.add_child(run)
