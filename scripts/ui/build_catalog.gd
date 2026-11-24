class_name BuildCatalog
extends ScreenBase

signal placement_requested(item_id: String)
signal adopt_requested(species_id: String)

const TABS: Array[String] = ["build", "animals", "park", "premium"]
const CATEGORIES: Array[String] = ["path", "plant", "decor", "building", "enclosure"]
const LIST_FADE_SECONDS := 0.18

var _tab: String = "build"
var _category: String = "path"
var _animate_list := false


func _ready() -> void:
	super()
	Platform.store.purchased.connect(_on_product_purchased)
	Platform.store.purchase_failed.connect(_on_purchase_failed)


func _build(_container: VBoxContainer) -> void:
	_add_header(UIKit.t("hud.build"))
	_root.add_child(UIKit.segmented(_options("build.tab.", TABS), _tab, _set_tab))
	if _tab == "build":
		_root.add_child(UIKit.chips(_options("cat.", CATEGORIES), _category, _set_category, "FilterChip"))
	var column := _add_scroll_body()
	if _animate_list:
		_fade_in(column)
	match _tab:
		"build":
			_fill_build(column)
		"animals":
			_fill_animals(column)
		"park":
			_fill_park(column)
		"premium":
			_fill_premium(column)


func _options(prefix: String, ids: Array[String]) -> Array:
	var options: Array = []
	for id in ids:
		options.append({"id": id, "text": UIKit.t(prefix + id)})
	return options


func _set_tab(tab: String) -> void:
	_tab = tab
	_rebuild_animated()


func _set_category(category: String) -> void:
	_category = category
	_rebuild_animated()


func _rebuild_animated() -> void:
	_animate_list = true
	_rebuild()
	_animate_list = false


func _fade_in(column: Control) -> void:
	column.modulate.a = 0.0
	var tween := column.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(column, "modulate:a", 1.0, LIST_FADE_SECONDS)


func _choose_item(item_id: String) -> void:
	placement_requested.emit(item_id)


func _choose_species(species_id: String) -> void:
	adopt_requested.emit(species_id)


func _fill_build(column: VBoxContainer) -> void:
	for item: Dictionary in Config.items_in(_category):
		var id: String = item["id"]
		var reason := ""
		if item["premium"] and not Platform.store.has_entitlement(StoreService.PREMIUM):
			reason = UIKit.t("error.premium_required")
		CatalogCard.add(column, UIKit.t("item." + id), _item_detail(item), item["cost"], int(item["unlock_level"]), _choose_item.bind(id), reason, ArtRegistry.get_texture(ArtRegistry.item_key(id)))


func _item_detail(item: Dictionary) -> String:
	var size: Array = item["size"]
	var detail := "%dx%d" % [int(size[0]), int(size[1])]
	if item["category"] == "enclosure":
		detail += " - " + UIKit.fmt("build.enclosure_detail", [UIKit.t("biome." + str(item["biome"])), int(item["capacity"])])
	return detail


func _fill_animals(column: VBoxContainer) -> void:
	for id: String in Config.species:
		var species: Dictionary = Config.species[id]
		var reason := ""
		if ParkService.enclosures_for(id).is_empty():
			reason = UIKit.t("error.no_enclosure")
		var detail := UIKit.t("biome." + str(species["biome"]))
		CatalogCard.add(column, UIKit.t("species." + id), detail, species["cost"], int(species["unlock_level"]), _choose_species.bind(id), reason, ArtRegistry.get_texture("animals/" + id))


func _fill_park(column: VBoxContainer) -> void:
	for expansion: Dictionary in Config.expansions:
		var id: String = expansion["id"]
		var size: int = expansion["size"]
		var reason := UIKit.t("build.owned") if size <= GameState.park.unlocked_size else ""
		CatalogCard.add(column, UIKit.t("item." + id), "%dx%d" % [size, size], expansion["cost"], int(expansion["unlock_level"]), _buy_expansion.bind(id), reason)


func _buy_expansion(id: String) -> void:
	var result: Dictionary = ParkService.buy_expansion(id)
	if result.get("ok", false):
		UIKit.toast(self, UIKit.t("build.expanded"))
	else:
		UIKit.toast_error(self, result.get("error", "insufficient_funds"))
	_rebuild()


func _fill_premium(column: VBoxContainer) -> void:
	for id in Platform.store.products():
		var card := UIKit.card(column)
		card.add_child(UIKit.label(UIKit.t("store." + id), "HeaderLabel", true))
		card.add_child(UIKit.label(UIKit.t("store.%s.desc" % id), "MutedLabel", true))
		if Platform.store.has_entitlement(id):
			card.add_child(UIKit.label(UIKit.t("build.owned"), "MutedLabel"))
		else:
			card.add_child(UIKit.primary_button(UIKit.t("store.buy"), _buy_product.bind(id)))
	column.add_child(UIKit.button(UIKit.t("profile.restore"), _restore))


func _buy_product(id: String) -> void:
	var result: Dictionary = Platform.store.purchase(id)
	if not result.get("ok", false):
		_on_purchase_failed(result.get("error", "store_unavailable"))


func _on_product_purchased(_product_id: String) -> void:
	UIKit.toast(self, UIKit.t("store.thanks"))
	_rebuild()


func _on_purchase_failed(error: String) -> void:
	UIKit.toast_error(self, error)


func _restore() -> void:
	Platform.store.restore()
	UIKit.toast(self, UIKit.t("profile.restored"))
	_rebuild()
