class_name CatalogCard
extends RefCounted

const PREVIEW_SIZE := 96.0
const LOCKED_ALPHA := 0.45


static func add(parent: Node, title: String, detail: String, cost: Dictionary, unlock_level: int, action: Callable, blocked_reason: String = "", preview: Texture2D = null) -> void:
	var row := UIKit.hbox(14)
	UIKit.card(parent).add_child(row)
	var reason := _reason(cost, unlock_level, blocked_reason)
	if preview != null:
		row.add_child(_preview(preview, reason != ""))
	row.add_child(_info(title, detail, cost, reason))
	if reason == "":
		var choose := UIKit.primary_button(UIKit.t("build.choose"), action)
		choose.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(choose)


static func _preview(texture: Texture2D, locked: bool) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(PREVIEW_SIZE, PREVIEW_SIZE)
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if locked:
		rect.modulate.a = LOCKED_ALPHA
	return rect


static func _info(title: String, detail: String, cost: Dictionary, reason: String) -> VBoxContainer:
	var info := UIKit.vbox(4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_child(UIKit.label(title, "HeaderLabel", true))
	info.add_child(UIKit.cost_row(cost))
	if detail != "":
		info.add_child(UIKit.label(detail, "MutedLabel", true))
	if reason != "":
		info.add_child(UIKit.label(reason, "MutedLabel", true))
	return info


static func _reason(cost: Dictionary, unlock_level: int, blocked_reason: String) -> String:
	if Economy.level() < unlock_level:
		return UIKit.fmt("build.locked_level", [unlock_level])
	if blocked_reason != "":
		return blocked_reason
	if not GameState.ledger.can_afford(cost):
		return UIKit.t("error.insufficient_funds")
	return ""
