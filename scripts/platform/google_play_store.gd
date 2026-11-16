class_name GooglePlayStore
extends StoreService

const SINGLETON := "GodotGooglePlayBilling"
const RESPONSE_OK := 0
const RESPONSE_USER_CANCELED := 1
const STATE_PURCHASED := 1

var _client: Node


static func available() -> bool:
	return Engine.has_singleton(SINGLETON)


func _init(client: Node) -> void:
	_client = client
	_client.connected.connect(_on_connected)
	_client.query_purchases_response.connect(_on_purchases_response)
	_client.on_purchase_updated.connect(_on_purchases_response)
	_client.start_connection()


func purchase(product_id: String) -> Dictionary:
	var check := _precheck(product_id)
	if not check["ok"]:
		return check
	if not _client.is_ready():
		return {"ok": false, "error": "store_unavailable"}
	var launch: Dictionary = _client.purchase(product_id)
	if int(launch.get("response_code", -1)) != RESPONSE_OK:
		return {"ok": false, "error": "store_unavailable"}
	return {"ok": true, "pending": true}


func restore() -> void:
	if _client.is_ready():
		_client.query_purchases(BillingClient.ProductType.INAPP)


func _on_connected() -> void:
	_client.query_product_details(PackedStringArray(PRODUCTS), BillingClient.ProductType.INAPP)
	_client.query_purchases(BillingClient.ProductType.INAPP)


func _on_purchases_response(response: Dictionary) -> void:
	var code := int(response.get("response_code", -1))
	if code == RESPONSE_USER_CANCELED:
		return
	if code != RESPONSE_OK:
		purchase_failed.emit("store_unavailable")
		return
	for entry: Dictionary in response.get("purchases", []):
		_process_purchase(entry)


func _process_purchase(entry: Dictionary) -> void:
	if int(entry.get("purchase_state", 0)) != STATE_PURCHASED:
		return
	if not entry.get("is_acknowledged", false):
		_client.acknowledge_purchase(str(entry["purchase_token"]))
	for product_id: String in entry.get("product_ids", []):
		_grant(product_id)
