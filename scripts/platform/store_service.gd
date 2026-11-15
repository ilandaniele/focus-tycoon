class_name StoreService
extends RefCounted

# Real stores need unconfirmed IAP plugins and developer accounts (docs/01 R4); only MockStore ships.

signal purchased(product_id: String)

const PREMIUM := "premium"


func products() -> Array[String]:
	return []


func has_entitlement(_product_id: String) -> bool:
	return false


func purchase(_product_id: String) -> Dictionary:
	return {"ok": false, "error": "unsupported"}


func restore() -> void:
	pass
