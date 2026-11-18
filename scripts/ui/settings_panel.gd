class_name SettingsPanel
extends VBoxContainer

const VOLUMES: Array[Dictionary] = [
	{"key": "vol_master", "label": "profile.vol_master"},
	{"key": "vol_music", "label": "profile.vol_music"},
	{"key": "vol_ambient", "label": "profile.vol_ambient"},
	{"key": "vol_sfx", "label": "profile.vol_sfx"},
]
const TEXT_SCALES: Array[float] = [1.0, 1.25, 1.5]
const REMINDER_ID := "daily_reminder"
const DAY_S := 86400

var _hour_label: Label
var _player_id_label: Label


func _ready() -> void:
	add_theme_constant_override("separation", 16)
	_build_language()
	_build_audio()
	_build_comfort()
	_build_reminders()
	if SyncService.enabled():
		_build_server_data()


func _build_language() -> void:
	var card := UIKit.card(self)
	card.add_child(UIKit.section_title(UIKit.t("profile.language")))
	var options := [{"id": "en", "text": "English"}, {"id": "es", "text": "Español"}]
	card.add_child(UIKit.chips(options, I18n.locale(), I18n.set_locale))


func _build_audio() -> void:
	var card := UIKit.card(self)
	card.add_child(UIKit.section_title(UIKit.t("profile.audio")))
	for volume in VOLUMES:
		var key: String = volume["key"]
		card.add_child(UIKit.labeled_slider(UIKit.t(volume["label"]), _setting(key, 1.0), _set_setting.bind(key)))


func _build_comfort() -> void:
	var card := UIKit.card(self)
	card.add_child(UIKit.switch_row(UIKit.t("profile.vibration"), _setting("vibration", true), _set_setting.bind("vibration")))
	card.add_child(UIKit.switch_row(UIKit.t("profile.reduce_motion"), _setting("reduce_motion", false), _set_setting.bind("reduce_motion")))
	card.add_child(UIKit.label(UIKit.t("profile.text_size"), "HeaderLabel"))
	var options: Array = []
	for scale in TEXT_SCALES:
		options.append({"id": scale, "text": "%d%%" % roundi(scale * 100.0)})
	card.add_child(UIKit.chips(options, _setting("text_scale", 1.0), _set_setting.bind("text_scale")))


func _build_reminders() -> void:
	var card := UIKit.card(self)
	card.add_child(UIKit.switch_row(UIKit.t("profile.reminders"), _setting("reminders_enabled", false), _set_reminders_enabled))
	var stepper := UIKit.hbox(12)
	stepper.add_child(UIKit.button("-", _step_hour.bind(-1)))
	_hour_label = UIKit.label("", "HeaderLabel")
	_hour_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hour_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stepper.add_child(_hour_label)
	stepper.add_child(UIKit.button("+", _step_hour.bind(1)))
	card.add_child(stepper)
	if not OS.has_feature("mobile"):
		card.add_child(UIKit.label(UIKit.t("profile.reminders_desktop"), "MutedLabel", true))
	_refresh_hour()


func _build_server_data() -> void:
	var card := UIKit.card(self)
	card.add_child(UIKit.section_title(UIKit.t("profile.server_data")))
	card.add_child(UIKit.label(UIKit.t("profile.server_data_body"), "MutedLabel", true))
	_player_id_label = UIKit.label("", "", true)
	card.add_child(_player_id_label)
	card.add_child(UIKit.button(UIKit.t("profile.copy_player_id"), _copy_player_id))
	card.add_child(UIKit.secondary_button(UIKit.t("profile.delete_server_data"), _confirm_delete_server_data))
	_refresh_player_id()


func _refresh_player_id() -> void:
	var player_id := SyncService.player_id()
	_player_id_label.text = UIKit.fmt("profile.player_id", [player_id if player_id != "" else "-"])


func _copy_player_id() -> void:
	DisplayServer.clipboard_set(SyncService.player_id())
	UIKit.toast(self, UIKit.t("profile.player_id_copied"))


func _confirm_delete_server_data() -> void:
	var dialog := ModalDialog.open(self, UIKit.t("profile.delete_title"))
	dialog.body.add_child(UIKit.label(UIKit.t("profile.delete_body"), "", true))
	dialog.add_button(UIKit.t("profile.delete_confirm"), true, _delete_server_data)
	dialog.add_button(UIKit.t("profile.delete_cancel"), false)


func _delete_server_data() -> void:
	var deleted: bool = await SyncService.delete_server_data()
	UIKit.toast(self, UIKit.t("profile.deleted" if deleted else "profile.delete_failed"))
	_refresh_player_id()


func _setting(key: String, fallback: Variant) -> Variant:
	return GameState.settings.get(key, fallback)


func _set_setting(value: Variant, key: String) -> void:
	GameState.set_setting(key, value)


func _set_reminders_enabled(enabled: bool) -> void:
	GameState.set_setting("reminders_enabled", enabled)
	_apply_reminder()


func _step_hour(delta: int) -> void:
	GameState.set_setting("reminder_hour", posmod(int(_setting("reminder_hour", 9)) + delta, 24))
	_refresh_hour()
	_apply_reminder()


func _refresh_hour() -> void:
	_hour_label.text = "%02d:00" % int(_setting("reminder_hour", 9))


func _apply_reminder() -> void:
	if not _setting("reminders_enabled", false):
		Platform.cancel_notification(REMINDER_ID)
		return
	var local_s: int = GameState.now() + GameState.clock.tz_offset_seconds()
	var wait_s := posmod(int(_setting("reminder_hour", 9)) * 3600 - local_s % DAY_S, DAY_S)
	Platform.schedule_notification(REMINDER_ID, maxi(wait_s, 60), UIKit.t("reminder.title"), UIKit.t("reminder.body"), DAY_S)
