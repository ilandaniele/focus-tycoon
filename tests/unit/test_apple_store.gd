extends TestCase

const PURCHASED := 4
const RESTORED := 5
const CANCELED := 7

var _kit: FakeStoreKit
var _store: AppleStore
var _purchased: Array[String] = []
var _failures: Array[String] = []


func before_each() -> void:
	GameState.reset_for_tests("user://test_apple_store/", FakeClock.new())
	_purchased.clear()
	_failures.clear()
	_kit = FakeStoreKit.new()
	_store = AppleStore.new(_kit)
	_store.purchased.connect(func(id: String) -> void: _purchased.append(id))
	_store.purchase_failed.connect(func(error: String) -> void: _failures.append(error))


func test_init_requests_every_product() -> void:
	assert_eq(_kit.info_requests, StoreService.PRODUCTS)


func test_purchase_launches_flow_without_granting() -> void:
	var result := _store.purchase(StoreService.PREMIUM)
	assert_true(result["ok"])
	assert_true(result["pending"])
	assert_eq(_kit.launched, [StoreService.PREMIUM] as Array[String])
	assert_false(_store.has_entitlement(StoreService.PREMIUM))


func test_purchased_and_restored_transactions_grant_once() -> void:
	_kit.transaction_state_changed.emit(_transaction(StoreService.PREMIUM, PURCHASED))
	_kit.transaction_state_changed.emit(_transaction(StoreService.PREMIUM, RESTORED))
	assert_eq(GameState.progress["entitlements"].count(StoreService.PREMIUM), 1)
	assert_eq(_purchased, [StoreService.PREMIUM] as Array[String])


func test_owned_product_info_grants() -> void:
	_kit.product_info_received.emit({"error": "", "product_id": "cosmetic_pack_garden", "is_purchased": true})
	_kit.product_info_received.emit({"error": "", "product_id": StoreService.PREMIUM, "is_purchased": false})
	assert_eq(_purchased, ["cosmetic_pack_garden"] as Array[String])


func test_cancel_is_silent_and_errors_are_reported() -> void:
	_kit.transaction_state_changed.emit(_transaction(StoreService.PREMIUM, CANCELED))
	assert_eq(_failures, [] as Array[String])
	_kit.transaction_state_changed.emit({"error": "network"})
	assert_eq(_failures, ["store_unavailable"] as Array[String])
	assert_false(_store.has_entitlement(StoreService.PREMIUM))


func test_unknown_product_is_ignored() -> void:
	_kit.transaction_state_changed.emit(_transaction("gems_9999", PURCHASED))
	assert_false(_store.has_entitlement("gems_9999"))


func test_purchase_rejected_when_owned() -> void:
	_kit.transaction_state_changed.emit(_transaction(StoreService.PREMIUM, PURCHASED))
	assert_eq(_store.purchase(StoreService.PREMIUM)["error"], "already_owned")
	assert_eq(_kit.launched, [] as Array[String])


func test_restore_syncs_and_requeries() -> void:
	_store.restore()
	assert_eq(_kit.syncs, 1)
	assert_eq(_kit.info_requests.size(), StoreService.PRODUCTS.size() * 2)


func _transaction(product_id: String, state: int) -> Dictionary:
	return {"error": "", "product_id": product_id, "transaction_state": state}
