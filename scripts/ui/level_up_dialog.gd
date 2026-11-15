class_name LevelUpDialog
extends RefCounted


static func show_card(from: Node, level: int, unlocked: Array) -> ModalDialog:
	var dialog := ModalDialog.open(from, UIKit.fmt("levelup.title", [level]))
	if not unlocked.is_empty():
		dialog.body.add_child(UIKit.label(UIKit.t("levelup.unlocked"), "HeaderLabel"))
	for id: String in unlocked:
		dialog.body.add_child(UIKit.label("- " + _name(id), "", true))
	dialog.add_button(UIKit.t("ui.continue"), true)
	return dialog


static func _name(id: String) -> String:
	if Config.species.has(id):
		return UIKit.t("species." + id)
	return UIKit.t("item." + id)
