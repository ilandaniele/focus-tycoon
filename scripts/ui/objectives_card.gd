class_name ObjectivesCard
extends PanelContainer

var _expanded: bool = false
var _body: VBoxContainer


func _ready() -> void:
	theme_type_variation = "CardPanel"
	_body = UIKit.vbox(8)
	add_child(_body)
	Economy.objectives_changed.connect(refresh)
	refresh()


func refresh() -> void:
	UIKit.clear(_body)
	var entries: Array = Economy.objectives_today()
	var done_count := 0
	var claimable := false
	for entry: Dictionary in entries:
		done_count += 1 if entry.get("claimed", false) else 0
		claimable = claimable or (entry.get("done", false) and not entry.get("claimed", false))
	var summary := UIKit.fmt("hud.objectives", [done_count, entries.size()])
	if claimable:
		summary += " - " + UIKit.t("hud.reward_ready")
	_body.add_child(UIKit.button(summary + ("  ^" if _expanded else "  v"), _toggle))
	if _expanded:
		for entry: Dictionary in entries:
			_body.add_child(_row(entry))


func _toggle() -> void:
	_expanded = not _expanded
	refresh()


func _row(entry: Dictionary) -> HBoxContainer:
	var row := UIKit.hbox(10)
	var id: String = entry.get("id", "")
	var progress := "%d/%d" % [int(entry.get("current", 0)), int(entry.get("target", 1))]
	row.add_child(UIKit.label("%s  %s" % [UIKit.t("obj." + id), progress], "", true))
	if entry.get("claimed", false):
		row.add_child(UIKit.label(UIKit.t("hud.claimed"), "MutedLabel"))
	elif entry.get("done", false):
		row.add_child(UIKit.primary_button(UIKit.t("hud.claim"), _claim.bind(id)))
	else:
		row.add_child(UIKit.label(UIKit.cost_text(entry.get("reward", {})), "MutedLabel"))
	return row


func _claim(id: String) -> void:
	var result: Dictionary = Economy.claim_objective(id)
	if not result.get("ok", false):
		UIKit.toast_error(self, result.get("error", "not_done"))
	refresh()
