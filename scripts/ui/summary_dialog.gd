class_name SummaryDialog
extends RefCounted

const COUNT_UP_S := 0.8


static func show_entries(from: Node, entries: Array) -> ModalDialog:
	var last := entries.back() as Dictionary
	var completed := _status(last) == "completed"
	var dialog := ModalDialog.open(from, UIKit.t("summary.title_done" if completed else "summary.title_partial"))
	var minutes := 0.0
	var totals := {"coins": 0, "nature": 0, "xp": 0}
	var capped := false
	for entry: Dictionary in entries:
		var record: Dictionary = entry.get("record", {})
		var reward: Dictionary = entry.get("reward", {})
		var effective := _minutes(entry["kind"], record)
		minutes += effective
		capped = capped or float(reward.get("counted_min", effective)) < effective - 0.01
		for key: String in totals:
			totals[key] += int(reward.get(key, 0))
	dialog.body.add_child(_centered(UIKit.fmt("summary.minutes", [int(minutes)]), "HeaderLabel"))
	for key: String in totals:
		var line := _centered("", "")
		dialog.body.add_child(line)
		_count_up(dialog, line, key, int(totals[key]))
	dialog.body.add_child(_centered(UIKit.t("summary.msg_done" if completed else "summary.msg_partial"), "MutedLabel"))
	if capped:
		dialog.body.add_child(_centered(UIKit.t("summary.cap_hint"), "MutedLabel"))
	dialog.add_button(UIKit.t("ui.continue"), true)
	return dialog


static func _status(entry: Dictionary) -> String:
	var record: Dictionary = entry.get("record", {})
	return record.get("status", "completed")


static func _minutes(kind: String, record: Dictionary) -> float:
	if kind == "meditation":
		return float(record.get("seconds", 0)) / 60.0
	return float(record.get("effective_min", 0.0))


static func _centered(text: String, variation: String) -> Label:
	var node := UIKit.label(text, variation, true)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return node


static func _count_up(dialog: ModalDialog, line: Label, kind: String, target: int) -> void:
	var render := func(value: float) -> void:
		line.text = "+%d %s" % [int(value), UIKit.t("ui.res." + kind)]
	render.call(float(target))
	if target > 0 and not UIKit.reduce_motion():
		dialog.create_tween().tween_method(render, 0.0, float(target), COUNT_UP_S)
