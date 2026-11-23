class_name ProfileScreen
extends ScreenBase

const DEBUG_STEPS: Array[Dictionary] = [
	{"label": "profile.debug_5min", "seconds": 300},
	{"label": "profile.debug_1h", "seconds": 3600},
]


func _build(_container: VBoxContainer) -> void:
	_add_header(UIKit.t("hud.profile"))
	var column := _add_scroll_body()
	_add_overview(column)
	column.add_child(SettingsPanel.new())
	column.add_child(UIKit.button(UIKit.t("profile.restore"), _restore))
	_add_credits(column)
	if OS.is_debug_build():
		_add_debug(column)


func _add_overview(column: VBoxContainer) -> void:
	var card := UIKit.card(column)
	card.add_child(UIKit.label(UIKit.fmt("hud.level", [Economy.level()]), "TitleLabel"))
	card.add_child(UIKit.label(UIKit.fmt("profile.objects", [GameState.park.objects.size()]), "", true))
	card.add_child(UIKit.section_title(UIKit.t("profile.collection")))
	card.add_child(SpeciesCollection.new())


func _add_credits(column: VBoxContainer) -> void:
	var card := UIKit.card(column)
	card.add_child(UIKit.section_title(UIKit.t("profile.credits")))
	card.add_child(UIKit.label(UIKit.t("profile.credits_body"), "MutedLabel", true))
	card.add_child(UIKit.label(UIKit.t("profile.credits_art"), "MutedLabel", true))
	card.add_child(UIKit.label(UIKit.t("profile.disclaimer"), "MutedLabel", true))


func _add_debug(column: VBoxContainer) -> void:
	for step in DEBUG_STEPS:
		column.add_child(UIKit.button(UIKit.t(step["label"]), _advance_clock.bind(int(step["seconds"]))))
	column.add_child(UIKit.button(UIKit.t("profile.debug_benchmark"), GameState.start_benchmark))


func _restore() -> void:
	Platform.store.restore()
	UIKit.toast(self, UIKit.t("profile.restored"))


func _advance_clock(seconds: int) -> void:
	GameState.debug_offset_s += seconds
	FocusService.tick_now()
