class_name FakeHttpTransport
extends HttpTransport

var responses: Array[Dictionary] = []
var requests: Array[Dictionary] = []


func send(method: HTTPClient.Method, url: String, headers: PackedStringArray, body: String) -> Dictionary:
	requests.append({"method": method, "url": url, "headers": headers, "body": JSON.parse_string(body)})
	return responses.pop_front() if not responses.is_empty() else {"code": 0, "body": null}


func paths() -> Array[String]:
	var result: Array[String] = []
	for request in requests:
		result.append(str(request["url"]).trim_prefix("https://demo.supabase.co"))
	return result
