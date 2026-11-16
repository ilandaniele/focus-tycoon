extends TestCase

const URL := "https://demo.supabase.co"
const NOW := 1_763_200_000
const INSERT_PATH := "/rest/v1/resource_transactions?on_conflict=player_id,idem_key"

var _transport: FakeHttpTransport
var _client: SupabaseClient
var _sync: LedgerSync
var _ledger: Ledger
var _synced: Dictionary


func before_each() -> void:
	_transport = FakeHttpTransport.new()
	_client = SupabaseClient.new(URL, "anon", _transport, 60)
	_sync = LedgerSync.new(_client, 2)
	_ledger = Ledger.new()
	_synced = {}
	_ledger.apply("starter_grant", {"coins": 300}, "tutorial", NOW)
	_ledger.apply("focus:s1#1", {"coins": 25, "nature": 2, "xp": 25}, "focus", NOW + 10)
	_ledger.apply("buy:o_1", {"coins": -40}, "build", NOW + 20)


func after_each() -> void:
	_transport.free()


func test_first_push_signs_up_and_uploads_a_batch() -> void:
	_transport.responses = [_auth_ok("user-1", "refresh-1"), {"code": 201, "body": null}]
	var result: Dictionary = await _sync.push(_ledger.entries(), _synced, NOW)
	assert_eq(result, {"ok": true, "sent": 2})
	assert_eq(_transport.paths(), ["/auth/v1/signup", INSERT_PATH] as Array[String])
	var rows: Array = _transport.requests[1]["body"]
	assert_eq(rows[1]["player_id"], "user-1")
	assert_eq(rows[1]["idem_key"], "focus:s1#1")
	assert_eq(rows[1]["delta_coins"], 25)
	assert_eq(rows[1]["delta_nature"], 2)
	assert_eq(rows[1]["delta_xp"], 25)
	assert_true(_synced.has("starter_grant") and _synced.has("focus:s1#1"))
	assert_false(_synced.has("buy:o_1"))


func test_failed_upload_is_retried_with_the_same_keys() -> void:
	_transport.responses = [_auth_ok("user-1", "refresh-1"), {"code": 503, "body": null}, {"code": 201, "body": null}]
	var failed: Dictionary = await _sync.push(_ledger.entries(), _synced, NOW)
	assert_false(failed["ok"])
	assert_true(_synced.is_empty())
	await _sync.push(_ledger.entries(), _synced, NOW + 5)
	var first_keys := _keys(_transport.requests[1]["body"])
	assert_eq(_keys(_transport.requests[2]["body"]), first_keys)
	assert_eq(_transport.requests[2]["headers"].has("Prefer: resolution=ignore-duplicates,return=minimal"), true)


func test_nothing_pending_sends_no_request() -> void:
	SyncBatch.mark_synced(_synced, _ledger.entries(), NOW)
	var result: Dictionary = await _sync.push(_ledger.entries(), _synced, NOW)
	assert_eq(result, {"ok": true, "sent": 0})
	assert_eq(_transport.requests.size(), 0)


func test_expired_session_refreshes_instead_of_signing_up() -> void:
	_client.session = {"access_token": "old", "refresh_token": "refresh-1", "expires_at": NOW + 30, "user_id": "user-1"}
	_transport.responses = [_auth_ok("user-1", "refresh-2"), {"code": 201, "body": null}]
	await _sync.push(_ledger.entries(), _synced, NOW)
	assert_eq(_transport.paths()[0], "/auth/v1/token?grant_type=refresh_token")
	assert_eq(_transport.requests[0]["body"], {"refresh_token": "refresh-1"})
	assert_eq(_client.session["refresh_token"], "refresh-2")


func test_valid_session_is_reused() -> void:
	_client.session = {"access_token": "live", "refresh_token": "r", "expires_at": NOW + 3600, "user_id": "user-1"}
	_transport.responses = [{"code": 201, "body": null}]
	await _sync.push(_ledger.entries(), _synced, NOW)
	assert_eq(_transport.paths(), [INSERT_PATH] as Array[String])
	assert_true(_transport.requests[0]["headers"].has("Authorization: Bearer live"))


func test_auth_failure_uploads_nothing() -> void:
	_transport.responses = [{"code": 422, "body": {"msg": "Anonymous sign-ins are disabled"}}]
	var result: Dictionary = await _sync.push(_ledger.entries(), _synced, NOW)
	assert_false(result["ok"])
	assert_eq(_transport.requests.size(), 1)
	assert_true(_synced.is_empty())


func test_prune_drops_keys_that_left_the_log() -> void:
	var synced := {"starter_grant": NOW, "gone": NOW}
	assert_eq(SyncBatch.prune(synced, _ledger.entries()), {"starter_grant": NOW})


func _auth_ok(user_id: String, refresh: String) -> Dictionary:
	return {"code": 200, "body": {"access_token": "access", "refresh_token": refresh, "expires_in": 3600, "user": {"id": user_id}}}


func _keys(rows: Array) -> Array:
	return rows.map(func(row: Dictionary) -> String: return row["idem_key"])
