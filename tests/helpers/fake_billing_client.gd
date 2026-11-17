class_name FakeBillingClient
extends Node

signal connected
signal query_purchases_response(response: Dictionary)
signal on_purchase_updated(response: Dictionary)

var billing_ready: bool = true
var launch_code: int = 0
var launched: Array[String] = []
var acknowledged: Array[String] = []
var purchase_queries: int = 0


func start_connection() -> void:
	connected.emit()


func is_ready() -> bool:
	return billing_ready


func query_product_details(_ids: PackedStringArray, _type: int) -> void:
	pass


func query_purchases(_type: int) -> void:
	purchase_queries += 1


func purchase(product_id: String) -> Dictionary:
	launched.append(product_id)
	return {"response_code": launch_code}


func acknowledge_purchase(token: String) -> void:
	acknowledged.append(token)
