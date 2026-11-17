class_name LedgerSync
extends RefCounted

var _client: SyncApiClient
var _batch_size: int


func _init(client: SyncApiClient, batch_size: int) -> void:
	_client = client
	_batch_size = batch_size


func push(entries: Array, synced: Dictionary, now: int) -> Dictionary:
	var batch := SyncBatch.pending(entries, synced, _batch_size)
	if batch.is_empty():
		return {"ok": true, "sent": 0}
	if not await _client.ensure_session():
		return {"ok": false, "sent": 0}
	if not await _client.insert_transactions(batch.map(SyncBatch.to_row)):
		return {"ok": false, "sent": 0}
	SyncBatch.mark_synced(synced, batch, now)
	return {"ok": true, "sent": batch.size()}
