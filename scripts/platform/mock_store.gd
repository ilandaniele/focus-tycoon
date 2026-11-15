class_name MockStore
extends StoreService

const PRODUCTS: Array[String] = ["premium", "cosmetic_pack_garden"]


func products() -> Array[String]:
	return PRODUCTS


func has_entitlement(product_id: String) -> bool:
	return product_id in _entitlements()


func purchase(product_id: String) -> Dictionary:
	if product_id not in PRODUCTS:
		return {"ok": false, "error": "unknown_product"}
	if has_entitlement(product_id):
		return {"ok": false, "error": "already_owned"}
	_entitlements().append(product_id)
	GameState.mark_dirty()
	purchased.emit(product_id)
	return {"ok": true}


func restore() -> void:
	for product_id: String in _entitlements().duplicate():
		purchased.emit(product_id)


func _entitlements() -> Array:
	return GameState.progress.get_or_add("entitlements", [])
