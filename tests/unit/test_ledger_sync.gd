extends TestCase

const NOW := 1_763_200_000
const PLAYERS_PATH := "/v1/players"
const TRANSACTIONS_PATH := "/v1/transactions"

var _transport: FakeHttpTransport
var _client: SyncApiClient
var _sync: LedgerSync
var _ledger: Ledger
var _synced: Dictionary


func before_each() -> void:
	_transport = FakeHttpTransport.new()
	_client = SyncApiClient.new(FakeHttpTransport.BASE_URL, _transport)
	_sync = LedgerSync.new(_client, 2)
	_ledger = Ledger.new()
	_synced = {}
	_ledger.apply("starter_grant", {"coins": 300}, "tutorial", NOW)
	_ledger.apply("focus:s1#1", {"coins": 25, "nature": 2, "xp": 25}, "focus", NOW + 10)
	_ledger.apply("buy:o_1", {"coins": -40}, "build", NOW + 20)


func after_each() -> void:
	_transport.free()


func test_first_push_signs_up_and_uploads_a_batch() -> void:
	_transport.responses = [_signup_ok("player-1", "token-1"), _accepted(2)]
	var result: Dictionary = await _sync.push(_ledger.entries(), _synced, NOW)
	assert_eq(result, {"ok": true, "sent": 2})
	assert_eq(_transport.paths(), [PLAYERS_PATH, TRANSACTIONS_PATH] as Array[String])
	assert_true(_transport.requests[1]["headers"].has("Authorization: Bearer token-1"))
	var rows: Array = _transport.requests[1]["body"]["transactions"]
	assert_false(rows[1].has("player_id"))
	assert_eq(rows[1]["idem_key"], "focus:s1#1")
	assert_eq(rows[1]["delta_coins"], 25)
	assert_eq(rows[1]["delta_nature"], 2)
	assert_eq(rows[1]["delta_xp"], 25)
	assert_eq(rows[1]["client_at"], Time.get_datetime_string_from_unix_time(NOW + 10) + "Z")
	assert_true(_synced.has("starter_grant") and _synced.has("focus:s1#1"))
	assert_false(_synced.has("buy:o_1"))


func test_failed_upload_is_retried_with_the_same_keys() -> void:
	_transport.responses = [_signup_ok("player-1", "token-1"), {"code": 503, "body": null}, _accepted(2)]
	var failed: Dictionary = await _sync.push(_ledger.entries(), _synced, NOW)
	assert_false(failed["ok"])
	assert_true(_synced.is_empty())
	await _sync.push(_ledger.entries(), _synced, NOW + 5)
	assert_eq(_transport.paths(), [PLAYERS_PATH, TRANSACTIONS_PATH, TRANSACTIONS_PATH] as Array[String])
	assert_eq(_keys(_transport.requests[2]["body"]), _keys(_transport.requests[1]["body"]))


func test_nothing_pending_sends_no_request() -> void:
	SyncBatch.mark_synced(_synced, _ledger.entries(), NOW)
	var result: Dictionary = await _sync.push(_ledger.entries(), _synced, NOW)
	assert_eq(result, {"ok": true, "sent": 0})
	assert_eq(_transport.requests.size(), 0)


func test_stored_session_is_reused() -> void:
	_client.session = {"player_id": "player-1", "token": "live"}
	_transport.responses = [_accepted(2)]
	await _sync.push(_ledger.entries(), _synced, NOW)
	assert_eq(_transport.paths(), [TRANSACTIONS_PATH] as Array[String])
	assert_true(_transport.requests[0]["headers"].has("Authorization: Bearer live"))


func test_rejected_token_clears_session_and_signs_up_again() -> void:
	_client.session = {"player_id": "player-1", "token": "revoked"}
	_transport.responses = [{"code": 401, "body": {"error": "unauthorized"}}, _signup_ok("player-2", "token-2"), _accepted(2)]
	var failed: Dictionary = await _sync.push(_ledger.entries(), _synced, NOW)
	assert_false(failed["ok"])
	assert_true(_client.session.is_empty())
	var retried: Dictionary = await _sync.push(_ledger.entries(), _synced, NOW + 5)
	assert_true(retried["ok"])
	assert_eq(_client.session["token"], "token-2")


func test_signup_failure_uploads_nothing() -> void:
	_transport.responses = [{"code": 429, "body": {"error": "rate_limited"}}]
	var result: Dictionary = await _sync.push(_ledger.entries(), _synced, NOW)
	assert_false(result["ok"])
	assert_eq(_transport.requests.size(), 1)
	assert_true(_synced.is_empty())


func test_prune_drops_keys_that_left_the_log() -> void:
	var synced := {"starter_grant": NOW, "gone": NOW}
	assert_eq(SyncBatch.prune(synced, _ledger.entries()), {"starter_grant": NOW})


func _signup_ok(player_id: String, token: String) -> Dictionary:
	return {"code": 201, "body": {"player_id": player_id, "token": token}}


func _accepted(count: int) -> Dictionary:
	return {"code": 200, "body": {"received": count, "accepted": count}}


func _keys(body: Dictionary) -> Array:
	return body["transactions"].map(func(row: Dictionary) -> String: return row["idem_key"])
