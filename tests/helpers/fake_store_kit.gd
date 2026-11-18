class_name FakeStoreKit
extends RefCounted

signal transaction_state_changed(transaction: Dictionary)
signal product_info_received(info: Dictionary)

var info_requests: Array[String] = []
var launched: Array[String] = []
var syncs: int = 0


func request_product_info(product_id: String) -> void:
	info_requests.append(product_id)


func purchase_product(product_id: String, _quantity: int) -> void:
	launched.append(product_id)


func sync() -> void:
	syncs += 1
