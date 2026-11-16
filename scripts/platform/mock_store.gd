class_name MockStore
extends StoreService


func purchase(product_id: String) -> Dictionary:
	var check := _precheck(product_id)
	if check["ok"]:
		_grant(product_id)
	return check
