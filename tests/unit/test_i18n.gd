extends TestCase

const LOCALE_FILES: Array[String] = ["res://locale/en.json", "res://locale/es.json"]


func before_each() -> void:
	GameState.reset_for_tests("user://test_i18n/", FakeClock.new())


func after_each() -> void:
	I18n.set_locale("en")


func test_locales_have_identical_keys() -> void:
	var en := _load("res://locale/en.json")
	var es := _load("res://locale/es.json")
	for key: String in en:
		assert_true(es.has(key), "missing in es: %s" % key)
	for key: String in es:
		assert_true(en.has(key), "missing in en: %s" % key)


func test_no_empty_values() -> void:
	for path in LOCALE_FILES:
		var messages := _load(path)
		assert_true(messages.size() > 0, "empty file %s" % path)
		for key: String in messages:
			assert_true(String(messages[key]).strip_edges() != "", "empty %s in %s" % [key, path])


func test_format_placeholders_match_between_locales() -> void:
	var en := _load("res://locale/en.json")
	var es := _load("res://locale/es.json")
	for key: String in en:
		if es.has(key):
			assert_eq(_placeholders(String(es[key])), _placeholders(String(en[key])), "placeholders differ: %s" % key)


func test_tr_returns_spanish_after_set_locale() -> void:
	I18n.set_locale("es")
	assert_eq(I18n.locale(), "es")
	assert_eq(str(TranslationServer.translate("ui.back")), "Volver")
	I18n.set_locale("en")
	assert_eq(str(TranslationServer.translate("ui.back")), "Back")


func test_unsupported_locale_falls_back_to_english() -> void:
	I18n.set_locale("fr")
	assert_eq(I18n.locale(), "en")


func test_set_locale_persists_in_settings() -> void:
	I18n.set_locale("es")
	assert_eq(GameState.settings.get("locale"), "es")


func _load(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "cannot parse %s" % path)
	return parsed if parsed is Dictionary else {}


func _placeholders(text: String) -> String:
	var found := ""
	for i in text.length() - 1:
		if text[i] == "%" and text[i + 1] in ["d", "s"]:
			found += text[i + 1]
	return found
