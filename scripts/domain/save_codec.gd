class_name SaveCodec
extends RefCounted

const SCHEMA_VERSION := 2
const RENAMED_SPECIES_V2 := {"panda": "koala", "polar_bear": "seal", "giraffe": "zebra"}


static func encode(data: Dictionary, at: int) -> String:
	var envelope: Dictionary = {"schema_version": SCHEMA_VERSION, "saved_at": at, "checksum": checksum_of(data), "data": data}
	return JSON.stringify(envelope, "\t", true)


static func decode(text: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return _failure("parse")
	var envelope: Dictionary = parsed
	if not envelope.has_all(["schema_version", "checksum", "data"]) or typeof(envelope["data"]) != TYPE_DICTIONARY:
		return _failure("format")
	var data: Dictionary = envelope["data"]
	if checksum_of(data) != envelope["checksum"]:
		return _failure("checksum")
	var version: int = int(envelope["schema_version"])
	if version < 1 or version > SCHEMA_VERSION:
		return _failure("unsupported_version")
	return {"ok": true, "data": _migrate(data, version), "error": ""}


static func checksum_of(data: Dictionary) -> String:
	var normalized: Variant = JSON.parse_string(JSON.stringify(data, "", true))
	return JSON.stringify(normalized, "", true).sha256_text()


static func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	if from_version < 2:
		_rename_species(data, RENAMED_SPECIES_V2)
	return data


static func _rename_species(data: Dictionary, renames: Dictionary) -> void:
	var animals: Variant = data.get("park", {}).get("animals", {})
	if typeof(animals) != TYPE_DICTIONARY:
		return
	for animal: Variant in animals.values():
		if typeof(animal) == TYPE_DICTIONARY and renames.has(animal.get("species_id")):
			animal["species_id"] = renames[animal["species_id"]]


static func _failure(error: String) -> Dictionary:
	return {"ok": false, "data": {}, "error": error}
