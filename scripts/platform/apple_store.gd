class_name AppleStore
extends StoreService

const NATIVE_CLASS := "GodotStoreKit2"
const STATE_PURCHASED := 4
const STATE_RESTORED := 5
const STATE_CANCELED := 7

var _kit: Object


static func available() -> bool:
	return ClassDB.class_exists(NATIVE_CLASS)


static func native_kit() -> Object:
	return ClassDB.instantiate(NATIVE_CLASS)


func _init(kit: Object) -> void:
	_kit = kit
	_kit.connect("transaction_state_changed", _on_transaction)
	_kit.connect("product_info_received", _on_product_info)
	_request_products()


func purchase(product_id: String) -> Dictionary:
	var check := _precheck(product_id)
	if not check["ok"]:
		return check
	_kit.call("purchase_product", product_id, 1)
	return {"ok": true, "pending": true}


func restore() -> void:
	_kit.call("sync")
	_request_products()


func _request_products() -> void:
	for product_id: String in PRODUCTS:
		_kit.call("request_product_info", product_id)


func _on_transaction(transaction: Dictionary) -> void:
	if not str(transaction.get("error", "")).is_empty():
		purchase_failed.emit("store_unavailable")
		return
	var state := int(transaction.get("transaction_state", -1))
	if state == STATE_PURCHASED or state == STATE_RESTORED:
		_grant(str(transaction.get("product_id", "")))


func _on_product_info(info: Dictionary) -> void:
	if str(info.get("error", "")).is_empty() and info.get("is_purchased", false):
		_grant(str(info.get("product_id", "")))
