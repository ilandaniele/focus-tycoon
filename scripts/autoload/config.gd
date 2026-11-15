extends Node

const DATA_DIR := "res://data/"

var economy: Dictionary = {}
var catalog: Dictionary = {}
var expansions: Array = []
var species: Dictionary = {}
var meditations: Dictionary = {}
var objectives: Dictionary = {}


func _ready() -> void:
	economy = ConfigLoader.load_json(DATA_DIR + "economy.json")
	var catalog_file: Dictionary = ConfigLoader.load_json(DATA_DIR + "catalog.json")
	catalog = _by_id(catalog_file["items"])
	expansions = catalog_file["expansions"]
	species = _by_id(ConfigLoader.load_json(DATA_DIR + "species.json")["species"])
	meditations = _by_id(ConfigLoader.load_json(DATA_DIR + "meditations.json")["exercises"])
	objectives = ConfigLoader.load_json(DATA_DIR + "objectives.json")


func item(id: String) -> Dictionary:
	return catalog.get(id, {})


func items_in(category: String) -> Array:
	return catalog.values().filter(func(definition: Dictionary) -> bool: return definition["category"] == category)


func _by_id(definitions: Array) -> Dictionary:
	var result: Dictionary = {}
	for definition: Dictionary in definitions:
		result[definition["id"]] = definition
	return result
