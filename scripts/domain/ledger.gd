class_name Ledger
extends RefCounted

const RESOURCES: Array[String] = ["coins", "nature", "xp"]
const MAX_LOG := 500

var balances: Dictionary = {"coins": 0, "nature": 0, "xp": 0}
var _applied_keys: Dictionary = {}
var _log: Array = []


func apply(key: String, delta: Dictionary, reason: String, at: int) -> Dictionary:
	if _applied_keys.has(key):
		return _result(true, true, "")
	var error := _validate(delta)
	if error != "":
		return _result(false, false, error)
	var clean: Dictionary = {}
	for resource: String in delta:
		clean[resource] = int(delta[resource])
		balances[resource] = get_balance(resource) + int(delta[resource])
	_applied_keys[key] = at
	_log.append({"key": key, "delta": clean, "reason": reason, "at": at})
	if _log.size() > MAX_LOG:
		_log = _log.slice(_log.size() - MAX_LOG)
	return _result(true, false, "")


func can_afford(cost: Dictionary) -> bool:
	for resource: String in cost:
		if get_balance(resource) < int(cost[resource]):
			return false
	return true


func get_balance(resource: String) -> int:
	return int(balances.get(resource, 0))


func entries() -> Array:
	return _log


func has_key(key: String) -> bool:
	return _applied_keys.has(key)


func to_dict() -> Dictionary:
	return {"balances": balances.duplicate(), "applied_keys": _applied_keys.duplicate(), "log": _log.duplicate(true)}


static func from_dict(d: Dictionary) -> Ledger:
	var ledger := Ledger.new()
	var saved_balances: Dictionary = d.get("balances", {})
	for resource in RESOURCES:
		ledger.balances[resource] = int(saved_balances.get(resource, 0))
	var saved_keys: Dictionary = d.get("applied_keys", {})
	for key: String in saved_keys:
		ledger._applied_keys[key] = int(saved_keys[key])
	ledger._log = d.get("log", []).duplicate(true)
	return ledger


func _validate(delta: Dictionary) -> String:
	for resource: String in delta:
		if not RESOURCES.has(resource):
			return "unknown_resource"
		var amount: int = int(delta[resource])
		if resource == "xp" and amount < 0:
			return "negative_xp"
		if get_balance(resource) + amount < 0:
			return "insufficient_funds"
	return ""


func _result(ok: bool, duplicate: bool, error: String) -> Dictionary:
	return {"ok": ok, "duplicate": duplicate, "error": error}
