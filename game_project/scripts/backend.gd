extends Node

signal request_failed(endpoint: String, error: String)
signal score_submitted(ok: bool)

const BASE_URL := "http://localhost:8080"
var auth_token := ""

func _ready() -> void:
	request_failed.connect(_on_request_failed)
	_load_place_services()


func _request(method: HTTPClient.Method, path: String, body := {}) -> Variant:
	var http := HTTPRequest.new()
	add_child(http)
	var headers := ["Content-Type: application/json"]
	if auth_token != "":
		headers.append("Authorization: Bearer " + auth_token)
	var err := http.request(BASE_URL + path, headers, method, JSON.stringify(body))
	if err != OK:
		http.queue_free()
		request_failed.emit(path, "Could not start request: %s" % error_string(err))
		return null

	var result = await http.request_completed
	http.queue_free()
	# result = [result_code, response_code, headers, body]
	if result[0] != HTTPRequest.RESULT_SUCCESS:
		request_failed.emit(path, "Request failed with result %d" % result[0])
		return null
	if result[1] < 200 or result[1] >= 300:
		request_failed.emit(path, "HTTP %d" % result[1])
		return null

	var response = JSON.parse_string(result[3].get_string_from_utf8())
	if response == null:
		request_failed.emit(path, "Response was not valid JSON")
	return response


func _load_place_services() -> void:
	var response: Variant = await _request(HTTPClient.METHOD_GET, "/get_coord")
	if not response is Array:
		if response != null:
			request_failed.emit("/get_coord", "Expected an array of coordinate pairs")
		return

	var place_pois: Array[POIData] = []
	for coordinates in response:
		if not coordinates is Array or coordinates.size() != 2:
			request_failed.emit("/get_coord", "Expected each place to contain latitude and longitude")
			return
		if coordinates[0] == null or coordinates[1] == null:
			continue
		if typeof(coordinates[0]) not in [TYPE_INT, TYPE_FLOAT] \
				or typeof(coordinates[1]) not in [TYPE_INT, TYPE_FLOAT]:
			request_failed.emit("/get_coord", "Coordinates must be numbers")
			return

		var latitude := float(coordinates[0])
		var longitude := float(coordinates[1])
		if latitude < -90.0 or latitude > 90.0 or longitude < -180.0 or longitude > 180.0:
			request_failed.emit("/get_coord", "Coordinates are outside valid latitude/longitude ranges")
			return

		var poi := POIData.new()
		poi.poi_name = "Place"
		poi.latitude = latitude
		poi.longitude = longitude
		place_pois.append(poi)

	if g.map == null:
		request_failed.emit("/get_coord", "Map node is not ready")
		return
	g.map.set_pois(place_pois)


func _on_request_failed(endpoint: String, error: String) -> void:
	push_error("Backend request failed (%s): %s" % [endpoint, error])


func submit_score(score: int) -> void:
	var res: Variant = await _request(HTTPClient.METHOD_POST, "/scores", {"score": score})
	score_submitted.emit(res is Dictionary and not res.is_empty())
