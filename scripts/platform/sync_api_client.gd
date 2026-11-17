class_name SyncApiClient
extends RefCounted

const PLAYERS_PATH := "/v1/players"
const TRANSACTIONS_PATH := "/v1/transactions"
const UNAUTHORIZED := 401

var session: Dictionary = {}
var _url: String
var _transport: HttpTransport


func _init(url: String, transport: HttpTransport) -> void:
	_url = url.trim_suffix("/")
	_transport = transport


func ensure_session() -> bool:
	if session.has("token"):
		return true
	var response: Dictionary = await _transport.send(HTTPClient.METHOD_POST, _url + PLAYERS_PATH, _headers(), "")
	var body: Variant = response["body"]
	if not _is_success(response["code"]) or not body is Dictionary or not body.has("token"):
		return false
	session = {"player_id": body["player_id"], "token": body["token"]}
	return true


func insert_transactions(rows: Array) -> bool:
	var headers := _headers()
	headers.append("Authorization: Bearer " + str(session["token"]))
	var payload := JSON.stringify({"transactions": rows})
	var response: Dictionary = await _transport.send(HTTPClient.METHOD_POST, _url + TRANSACTIONS_PATH, headers, payload)
	if response["code"] == UNAUTHORIZED:
		session = {}
	return _is_success(response["code"])


func _headers() -> PackedStringArray:
	return PackedStringArray(["Content-Type: application/json"])


func _is_success(code: int) -> bool:
	return code >= 200 and code < 300
