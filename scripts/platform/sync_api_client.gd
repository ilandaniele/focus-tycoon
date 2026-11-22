class_name SyncApiClient
extends RefCounted

const PLAYERS_PATH := "/v1/players"
const TRANSACTIONS_PATH := "/v1/transactions"
const FEEDBACK_PATH := "/v1/feedback"
const FEEDBACK_MAX_CHARS := 1000
const REJECTED := 400
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
	if not is_success(response["code"]) or not body is Dictionary or not body.has("token"):
		return false
	session = {"player_id": body["player_id"], "token": body["token"]}
	return true


func insert_transactions(rows: Array) -> int:
	return await _post_authenticated(TRANSACTIONS_PATH, {"transactions": rows})


func send_feedback(feedback: Dictionary) -> bool:
	if not await ensure_session():
		return false
	return is_success(await _post_authenticated(FEEDBACK_PATH, feedback))


func _post_authenticated(path: String, body: Dictionary) -> int:
	var response: Dictionary = await _transport.send(HTTPClient.METHOD_POST, _url + path, _auth_headers(), JSON.stringify(body))
	if response["code"] == UNAUTHORIZED:
		session = {}
	return response["code"]


func delete_player() -> bool:
	if not session.has("token"):
		return true
	var response: Dictionary = await _transport.send(HTTPClient.METHOD_DELETE, _url + PLAYERS_PATH, _auth_headers(), "")
	if not is_success(response["code"]) and response["code"] != UNAUTHORIZED:
		return false
	session = {}
	return true


func _auth_headers() -> PackedStringArray:
	var headers := _headers()
	headers.append("Authorization: Bearer " + str(session["token"]))
	return headers


func _headers() -> PackedStringArray:
	return PackedStringArray(["Content-Type: application/json"])


static func is_success(code: int) -> bool:
	return code >= 200 and code < 300
