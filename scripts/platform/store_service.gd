class_name StoreService
extends RefCounted

signal purchased(product_id: String)
signal purchase_failed(error: String)

const PREMIUM := "premium"
const PRODUCTS: Array[String] = [PREMIUM, "cosmetic_pack_garden"]


func products() -> Array[String]:
	return PRODUCTS


func has_entitlement(product_id: String) -> bool:
	return product_id in _entitlements()


func purchase(_product_id: String) -> Dictionary:
	return {"ok": false, "error": "store_unavailable"}


func restore() -> void:
	pass


func _precheck(product_id: String) -> Dictionary:
	if product_id not in PRODUCTS:
		return {"ok": false, "error": "unknown_product"}
	if has_entitlement(product_id):
		return {"ok": false, "error": "already_owned"}
	return {"ok": true}


func _grant(product_id: String) -> void:
	if product_id not in PRODUCTS or has_entitlement(product_id):
		return
	_entitlements().append(product_id)
	GameState.mark_dirty()
	purchased.emit(product_id)


func _entitlements() -> Array:
	return GameState.progress.get_or_add("entitlements", [])
