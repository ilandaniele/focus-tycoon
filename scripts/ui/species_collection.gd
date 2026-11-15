class_name SpeciesCollection
extends HBoxContainer


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	var owned := _owned_species()
	for id: String in Config.species:
		add_child(_badge(id, id in owned))


func _owned_species() -> Array[String]:
	var owned: Array[String] = []
	for animal: Dictionary in GameState.park.animals.values():
		owned.append(animal["species_id"])
	return owned


func _badge(id: String, owned: bool) -> VBoxContainer:
	var column := UIKit.vbox(4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var silhouette := Silhouette.new()
	silhouette.color = Color(Config.species[id]["color"]) if owned else Color(ThemeFactory.INK, 0.25)
	silhouette.custom_minimum_size = Vector2(0, 80)
	column.add_child(silhouette)
	var name_label := UIKit.label(UIKit.t("species." + id) if owned else "?", "MutedLabel")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	column.add_child(name_label)
	return column


class Silhouette extends Control:
	var color: Color = Color.WHITE

	func _draw() -> void:
		var center := size / 2.0
		draw_set_transform(center + Vector2(0, 8), 0.0, Vector2(1.3, 1.0))
		draw_circle(Vector2.ZERO, 22.0, color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_circle(center + Vector2(-16, -14), 10.0, color)
		draw_circle(center + Vector2(16, -14), 10.0, color)
