class_name ConfigLoader
extends RefCounted


static func load_json(path: String) -> Variant:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	assert(parsed != null, "invalid or missing JSON: %s" % path)
	return parsed
