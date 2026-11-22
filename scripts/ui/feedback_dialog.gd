class_name FeedbackDialog
extends RefCounted

const CATEGORIES: Array[String] = ["bug", "idea", "other"]
const TEXT_HEIGHT := 240.0


static func open(from: Node) -> void:
	var dialog := ModalDialog.open(from, UIKit.t("feedback.title"))
	dialog.body.add_child(UIKit.label(UIKit.t("feedback.body"), "MutedLabel", true))
	var choice := {"category": CATEGORIES[0]}
	var options: Array = CATEGORIES.map(func(id: String) -> Dictionary: return {"id": id, "text": UIKit.t("feedback.cat_" + id)})
	dialog.body.add_child(UIKit.chips(options, choice["category"], func(id: String) -> void: choice["category"] = id))
	var text := TextEdit.new()
	text.placeholder_text = UIKit.t("feedback.placeholder")
	text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	text.custom_minimum_size = Vector2(0, TEXT_HEIGHT)
	dialog.body.add_child(text)
	var message := {"text": ""}
	text.text_changed.connect(func() -> void: message["text"] = text.text)
	dialog.add_button(UIKit.t("feedback.send"), true, func() -> void: _send(from, choice["category"], message["text"]))
	dialog.add_button(UIKit.t("feedback.cancel"), false)


static func _send(from: Node, category: String, message: String) -> void:
	if message.strip_edges() == "":
		UIKit.toast(from, UIKit.t("feedback.empty"))
		return
	var sent: bool = await SyncService.send_feedback(category, message)
	UIKit.toast(from, UIKit.t("feedback.sent" if sent else "feedback.failed"))
