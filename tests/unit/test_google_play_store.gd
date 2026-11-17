extends TestCase

var _client: FakeBillingClient
var _store: GooglePlayStore
var _purchased: Array[String] = []
var _failures: Array[String] = []


func before_each() -> void:
	GameState.reset_for_tests("user://test_google_play_store/", FakeClock.new())
	_purchased.clear()
	_failures.clear()
	_client = FakeBillingClient.new()
	_store = GooglePlayStore.new(_client)
	_store.purchased.connect(func(id: String) -> void: _purchased.append(id))
	_store.purchase_failed.connect(func(error: String) -> void: _failures.append(error))


func after_each() -> void:
	_client.free()


func test_connect_queries_existing_purchases() -> void:
	assert_eq(_client.purchase_queries, 1)


func test_purchase_launches_flow_without_granting() -> void:
	var result := _store.purchase(StoreService.PREMIUM)
	assert_true(result["ok"])
	assert_true(result["pending"])
	assert_eq(_client.launched, [StoreService.PREMIUM] as Array[String])
	assert_false(_store.has_entitlement(StoreService.PREMIUM))


func test_completed_purchase_grants_and_acknowledges_once() -> void:
	var update := _response([_purchase(StoreService.PREMIUM, 1, false)])
	_client.on_purchase_updated.emit(update)
	_client.on_purchase_updated.emit(update)
	assert_true(_store.has_entitlement(StoreService.PREMIUM))
	assert_eq(GameState.progress["entitlements"].count(StoreService.PREMIUM), 1)
	assert_eq(_purchased, [StoreService.PREMIUM] as Array[String])
	assert_eq(_client.acknowledged, ["token_premium", "token_premium"] as Array[String])


func test_pending_purchase_grants_nothing() -> void:
	_client.on_purchase_updated.emit(_response([_purchase(StoreService.PREMIUM, 2, false)]))
	assert_false(_store.has_entitlement(StoreService.PREMIUM))
	assert_eq(_client.acknowledged, [] as Array[String])


func test_acknowledged_purchase_is_not_acknowledged_again() -> void:
	_client.query_purchases_response.emit(_response([_purchase(StoreService.PREMIUM, 1, true)]))
	assert_true(_store.has_entitlement(StoreService.PREMIUM))
	assert_eq(_client.acknowledged, [] as Array[String])


func test_unknown_product_from_store_is_ignored() -> void:
	_client.on_purchase_updated.emit(_response([_purchase("gems_9999", 1, true)]))
	assert_false(_store.has_entitlement("gems_9999"))


func test_user_cancel_is_silent_and_errors_are_reported() -> void:
	_client.on_purchase_updated.emit({"response_code": 1})
	assert_eq(_failures, [] as Array[String])
	_client.on_purchase_updated.emit({"response_code": 6})
	assert_eq(_failures, ["store_unavailable"] as Array[String])


func test_purchase_rejected_when_disconnected_or_owned() -> void:
	_client.billing_ready = false
	assert_eq(_store.purchase(StoreService.PREMIUM)["error"], "store_unavailable")
	_client.billing_ready = true
	_client.launch_code = 5
	assert_eq(_store.purchase(StoreService.PREMIUM)["error"], "store_unavailable")
	_client.query_purchases_response.emit(_response([_purchase(StoreService.PREMIUM, 1, true)]))
	assert_eq(_store.purchase(StoreService.PREMIUM)["error"], "already_owned")


func test_restore_requeries_purchases() -> void:
	_store.restore()
	assert_eq(_client.purchase_queries, 2)


func _response(purchases: Array) -> Dictionary:
	return {"response_code": 0, "purchases": purchases}


func _purchase(product_id: String, state: int, acknowledged: bool) -> Dictionary:
	return {
		"product_ids": [product_id],
		"purchase_state": state,
		"purchase_token": "token_" + product_id,
		"is_acknowledged": acknowledged,
	}
