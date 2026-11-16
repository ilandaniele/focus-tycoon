class_name SupabaseClient
extends RefCounted

const TRANSACTIONS_PATH := "/rest/v1/resource_transactions?on_conflict=player_id,idem_key"

var session: Dictionary = {}
var _url: String
var _anon_key: String
var _transport: HttpTransport
var _token_margin_s: int


func _init(url: String, anon_key: String, transport: HttpTransport, token_margin_s: int) -> void:
	_url = url.trim_suffix("/")
	_anon_key = anon_key
	_transport = transport
	_token_margin_s = token_margin_s


func ensure_session(now: int) -> bool:
	if session.has("refresh_token") and now < int(session["expires_at"]) - _token_margin_s:
		return true
	if session.has("refresh_token"):
		var refreshed: Dictionary = await _auth("/auth/v1/token?grant_type=refresh_token", {"refresh_token": session["refresh_token"]}, now)
		if refreshed["ok"]:
			return true
	var created: Dictionary = await _auth("/auth/v1/signup", {}, now)
	return created["ok"]


func insert_transactions(rows: Array) -> bool:
	var headers := _headers(session["access_token"])
	headers.append("Prefer: resolution=ignore-duplicates,return=minimal")
	var response: Dictionary = await _transport.send(HTTPClient.METHOD_POST, _url + TRANSACTIONS_PATH, headers, JSON.stringify(rows))
	return _is_success(response["code"])


func _auth(path: String, payload: Dictionary, now: int) -> Dictionary:
	var response: Dictionary = await _transport.send(HTTPClient.METHOD_POST, _url + path, _headers(_anon_key), JSON.stringify(payload))
	var body: Variant = response["body"]
	if not _is_success(response["code"]) or not body is Dictionary or not body.has("refresh_token"):
		return {"ok": false}
	session = {
		"access_token": body["access_token"],
		"refresh_token": body["refresh_token"],
		"expires_at": now + int(body.get("expires_in", 0)),
		"user_id": body["user"]["id"],
	}
	return {"ok": true}


func _headers(bearer: String) -> PackedStringArray:
	return PackedStringArray(["apikey: " + _anon_key, "Authorization: Bearer " + bearer, "Content-Type: application/json"])


func _is_success(code: int) -> bool:
	return code >= 200 and code < 300
