class_name SummaryDialog
extends RefCounted

const COUNT_UP_S := 0.8


static func show_entries(from: Node, entries: Array) -> ModalDialog:
	var summary := SessionSummary.build(entries)
	var minutes: int = summary["minutes"]
	var rewards: Dictionary = summary["rewards"]
	var dialog := ModalDialog.open(from, UIKit.t(summary["title_key"]))
	if minutes > 0:
		dialog.body.add_child(_centered(UIKit.fmt("summary.minutes_one" if minutes == 1 else "summary.minutes", [minutes]), "HeaderLabel"))
	for key: String in rewards:
		var line := _centered("", "")
		dialog.body.add_child(line)
		_count_up(dialog, line, key, int(rewards[key]))
	dialog.body.add_child(_centered(UIKit.t(summary["message_key"]), "MutedLabel"))
	if summary["capped"]:
		dialog.body.add_child(_centered(UIKit.t("summary.cap_hint"), "MutedLabel"))
	dialog.add_button(UIKit.t("ui.continue"), true)
	return dialog


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
