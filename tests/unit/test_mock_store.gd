extends TestCase

var _purchased: Array[String] = []


func before_each() -> void:
	GameState.reset_for_tests("user://test_mock_store/", FakeClock.new())
	_purchased.clear()


func test_purchase_grants_entitlement_once() -> void:
	var store := _store()
	var first := store.purchase(StoreService.PREMIUM)
	var second := store.purchase(StoreService.PREMIUM)
	assert_true(first["ok"])
	assert_false(second["ok"])
	assert_eq(second["error"], "already_owned")
	assert_true(store.has_entitlement(StoreService.PREMIUM))
	assert_eq(GameState.progress["entitlements"].count(StoreService.PREMIUM), 1)
	assert_eq(_purchased, [StoreService.PREMIUM] as Array[String])


func test_unknown_product_rejected() -> void:
	var store := _store()
	var result := store.purchase("gems_9999")
	assert_false(result["ok"])
	assert_eq(result["error"], "unknown_product")
	assert_false(store.has_entitlement("gems_9999"))


func test_restore_reemits_owned_products() -> void:
	var store := _store()
	store.purchase(StoreService.PREMIUM)
	_purchased.clear()
	store.restore()
	assert_eq(_purchased, [StoreService.PREMIUM] as Array[String])


func test_fresh_store_has_no_entitlements() -> void:
	assert_false(_store().has_entitlement(StoreService.PREMIUM))


func _store() -> MockStore:
	var store := MockStore.new()
	store.purchased.connect(_on_purchased)
	return store


func _on_purchased(product_id: String) -> void:
	_purchased.append(product_id)
