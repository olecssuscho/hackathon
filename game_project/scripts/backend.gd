extends Node

signal request_failed(endpoint: String, error: String)
signal score_submitted(ok: bool)

const BASE_URL := "https://api.example.com"
var auth_token := ""

func _request(method: HTTPClient.Method, path: String, body := {}) -> Dictionary:
	var http := HTTPRequest.new()
	add_child(http)
	var headers := ["Content-Type: application/json"]
	if auth_token != "":
		headers.append("Authorization: Bearer " + auth_token)
	http.request(BASE_URL + path, headers, method, JSON.stringify(body))
	var result = await http.request_completed
	http.queue_free()
	# result = [result_code, response_code, headers, body]
	if result[0] != HTTPRequest.RESULT_SUCCESS or result[1] >= 400:
		request_failed.emit(path, "HTTP %d" % result[1])
		return {}
	return JSON.parse_string(result[3].get_string_from_utf8())

func submit_score(score: int) -> void:
	var res := await _request(HTTPClient.METHOD_POST, "/scores", {"score": score})
	score_submitted.emit(not res.is_empty())
