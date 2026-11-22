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
	var missions: Array = Economy.mission_chains()
	var done_count := 0
	var claimable := false
	for entry: Dictionary in entries:
		done_count += 1 if entry.get("claimed", false) else 0
		claimable = claimable or (entry.get("done", false) and not entry.get("claimed", false))
	for mission: Dictionary in missions:
		claimable = claimable or mission.get("done", false)
	var summary := UIKit.fmt("hud.objectives", [done_count, entries.size()])
	if claimable:
		summary += " - " + UIKit.t("hud.reward_ready")
	var toggle := UIKit.button(summary, _toggle)
	toggle.icon = UIKit.icon("chevron_up" if _expanded else "chevron_down")
	toggle.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_body.add_child(toggle)
	if _expanded:
		for entry: Dictionary in entries:
			_body.add_child(_row(_objective_text(entry), entry, _claim.bind(entry.get("id", ""))))
		_body.add_child(UIKit.section_title(UIKit.t("hud.missions")))
		for mission: Dictionary in missions:
			_body.add_child(_row(_mission_text(mission), mission, _claim_mission.bind(mission["id"])))


func _toggle() -> void:
	_expanded = not _expanded
	refresh()


func _objective_text(entry: Dictionary) -> String:
	return "%s  %s" % [UIKit.t("obj." + entry.get("id", "")), _progress_text(entry)]


func _mission_text(mission: Dictionary) -> String:
	var title := "%s %d/%d" % [UIKit.t("chain." + mission["id"]), mini(mission["step"] + 1, mission["steps"]), mission["steps"]]
	if mission["finished"]:
		return title
	return "%s: %s  %s" % [title, UIKit.fmt("mission." + mission["metric"], [int(mission["target"])]), _progress_text(mission)]


func _progress_text(entry: Dictionary) -> String:
	return "%d/%d" % [int(entry.get("current", 0)), int(entry.get("target", 1))]


func _row(text: String, entry: Dictionary, on_claim: Callable) -> HBoxContainer:
	var row := UIKit.hbox(10)
	row.add_child(UIKit.label(text, "", true))
	if entry.get("claimed", false) or entry.get("finished", false):
		row.add_child(UIKit.label(UIKit.t("hud.claimed"), "MutedLabel"))
	elif entry.get("done", false):
		row.add_child(UIKit.primary_button(UIKit.t("hud.claim"), on_claim))
	else:
		row.add_child(UIKit.label(UIKit.cost_text(entry.get("reward", {})), "MutedLabel"))
	return row


func _claim(id: String) -> void:
	var result: Dictionary = Economy.claim_objective(id)
	if not result.get("ok", false):
		UIKit.toast_error(self, result.get("error", "not_done"))
	refresh()


func _claim_mission(chain_id: String) -> void:
	var result: Dictionary = Economy.claim_mission(chain_id)
	if not result.get("ok", false):
		UIKit.toast_error(self, result.get("error", "not_done"))
	refresh()
