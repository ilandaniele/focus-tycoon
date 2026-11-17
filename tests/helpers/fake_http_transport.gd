class_name FakeHttpTransport
extends HttpTransport

const BASE_URL := "https://api.test"

var responses: Array[Dictionary] = []
var requests: Array[Dictionary] = []


func send(method: HTTPClient.Method, url: String, headers: PackedStringArray, body: String) -> Dictionary:
	requests.append({"method": method, "url": url, "headers": headers, "body": JSON.parse_string(body) if body != "" else null})
	return responses.pop_front() if not responses.is_empty() else {"code": 0, "body": null}


func paths() -> Array[String]:
	var result: Array[String] = []
	for request in requests:
		result.append(str(request["url"]).trim_prefix(BASE_URL))
	return result
