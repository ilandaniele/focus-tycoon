class_name HttpTransport
extends Node

var timeout_s: float = 10.0


func send(method: HTTPClient.Method, url: String, headers: PackedStringArray, body: String) -> Dictionary:
	var request := HTTPRequest.new()
	request.timeout = timeout_s
	add_child(request)
	if request.request(url, headers, method, body) != OK:
		request.queue_free()
		return {"code": 0, "body": null}
	var response: Array = await request.request_completed
	request.queue_free()
	var text := (response[3] as PackedByteArray).get_string_from_utf8()
	return {"code": int(response[1]), "body": JSON.parse_string(text) if text != "" else null}
