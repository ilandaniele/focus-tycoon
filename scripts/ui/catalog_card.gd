class_name CatalogCard
extends RefCounted


static func add(parent: Node, title: String, detail: String, cost: Dictionary, unlock_level: int, action: Callable, blocked_reason: String = "") -> void:
	var card := UIKit.card(parent)
	var header := UIKit.hbox(10)
	card.add_child(header)
	header.add_child(UIKit.label(title, "HeaderLabel", true))
	header.add_child(UIKit.label(UIKit.cost_text(cost), "MutedLabel"))
	if detail != "":
		card.add_child(UIKit.label(detail, "MutedLabel", true))
	var reason := _reason(cost, unlock_level, blocked_reason)
	if reason == "":
		card.add_child(UIKit.primary_button(UIKit.t("build.choose"), action))
	else:
		var button := UIKit.button(reason, action)
		button.disabled = true
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(button)


static func _reason(cost: Dictionary, unlock_level: int, blocked_reason: String) -> String:
	if Economy.level() < unlock_level:
		return UIKit.fmt("build.locked_level", [unlock_level])
	if blocked_reason != "":
		return blocked_reason
	if not GameState.ledger.can_afford(cost):
		return UIKit.t("error.insufficient_funds")
	return ""
