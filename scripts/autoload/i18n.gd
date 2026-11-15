extends Node

signal locale_changed

const LOCALE_DIR := "res://locale/"
const SUPPORTED: Array[String] = ["en", "es"]
const FALLBACK := "en"

var _locale: String = FALLBACK


func _ready() -> void:
	for code in SUPPORTED:
		_register(code)
	_apply(OS.get_locale_language())
	_bind_game_state.call_deferred()


func locale() -> String:
	return _locale


func set_locale(code: String) -> void:
	_apply(code)
	GameState.set_setting("locale", _locale)


func _apply(code: String) -> void:
	var normalized := code.substr(0, 2).to_lower()
	if normalized not in SUPPORTED:
		normalized = FALLBACK
	if normalized == _locale and TranslationServer.get_locale() == normalized:
		return
	_locale = normalized
	TranslationServer.set_locale(normalized)
	locale_changed.emit()


func _register(code: String) -> void:
	var text := FileAccess.get_file_as_string("%s%s.json" % [LOCALE_DIR, code])
	var messages: Variant = JSON.parse_string(text)
	if not messages is Dictionary:
		push_error("I18n: cannot parse locale %s" % code)
		return
	var translation := Translation.new()
	translation.locale = code
	for key: String in messages:
		translation.add_message(key, String(messages[key]))
	TranslationServer.add_translation(translation)


func _bind_game_state() -> void:
	GameState.state_loaded.connect(_apply_saved_locale)
	GameState.settings_changed.connect(_on_setting_changed)
	_apply_saved_locale()


func _apply_saved_locale() -> void:
	var saved: String = GameState.settings.get("locale", "")
	if saved != "":
		_apply(saved)


func _on_setting_changed(key: String) -> void:
	if key == "locale":
		_apply_saved_locale()
