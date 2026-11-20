extends Node

signal request_failed(endpoint: String, error: String)
signal score_submitted(ok: bool)

const BASE_URL := "https://hackathon-j2q3.onrender.com"
var auth_token := ""
var _auth_callback: JavaScriptObject

func _ready() -> void:
	request_failed.connect(_on_request_failed)
	if OS.has_feature("web"):
		_listen_for_auth_token()
	_load_place_services()


func _listen_for_auth_token() -> void:
	_auth_callback = JavaScriptBridge.create_callback(_on_auth_message)
	var window: JavaScriptObject = JavaScriptBridge.get_interface("window")
	window.set("godotAuthTokenCallback", _auth_callback)
	JavaScriptBridge.eval("""
		window.addEventListener("message", (event) => {
			if (event.source !== window.parent || event.data?.type !== "AUTH_TOKEN") return;
			window.godotAuthTokenCallback(event.data.accessToken);
		});
		window.parent.postMessage({ type: "GODOT_READY" }, "*");
	""")


func _on_auth_message(args: Array) -> void:
	if args.size() != 1 or typeof(args[0]) != TYPE_STRING or args[0].is_empty():
		push_error("Frontend sent an invalid access token")
		return
	auth_token = args[0]


func _request(method: HTTPClient.Method, path: String, body := {}) -> Variant:
	var http := HTTPRequest.new()
	add_child(http)
	var headers := PackedStringArray()
	var request_body := ""
	if method != HTTPClient.METHOD_GET and method != HTTPClient.METHOD_HEAD:
		headers.append("Content-Type: application/json")
		request_body = JSON.stringify(body)
	if auth_token != "":
		headers.append("Authorization: Bearer " + auth_token)
	var err := http.request(BASE_URL + path, headers, method, request_body)
	if err != OK:
		http.queue_free()
		request_failed.emit(path, "Could not start request: %s" % error_string(err))
		return null

	var result = await http.request_completed
	http.queue_free()
	# result = [result_code, response_code, headers, body]
	if result[0] != HTTPRequest.RESULT_SUCCESS:
		var error_message := "Request failed with result %d" % result[0]
		if result[0] == HTTPRequest.RESULT_CONNECTION_ERROR:
			error_message = "Connection error to %s" % (BASE_URL + path)
		request_failed.emit(path, error_message)
		return null
	if result[1] < 200 or result[1] >= 300:
		request_failed.emit(path, "HTTP %d" % result[1])
		return null

	var response = JSON.parse_string(result[3].get_string_from_utf8())
	if response == null:
		request_failed.emit(path, "Response was not valid JSON")
	return response


func _load_place_services() -> void:
	if g.map == null:
		request_failed.emit("/get_coord", "Map node is not ready")
		return
	var points_label := g.map.get_node_or_null("../UI/points") as Label
	if points_label == null:
		request_failed.emit("/get_coord", "Points label was not found")
		return
	points_label.text = "Loading places..."

	var response: Variant = await _request(HTTPClient.METHOD_GET, "/get_coord")
	if not response is Array:
		if response != null:
			request_failed.emit("/get_coord", "Expected an array of coordinate pairs")
		return

	var place_lines := PackedStringArray()
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

		var details_path := "/place?lat=%s&lon=%s" % [str(latitude), str(longitude)]
		var details: Variant = await _request(HTTPClient.METHOD_GET, details_path)
		if details == null:
			continue
		if not details is Dictionary:
			request_failed.emit(details_path, "Expected place details as an object")
			return

		var line := "%s, %s" % [str(latitude), str(longitude)]
		var place_name: Variant = details.get("name", "")
		if place_name is String and not place_name.is_empty():
			line += " — " + place_name
		place_lines.append(line)
		points_label.text = "\n".join(place_lines)

	if place_lines.is_empty():
		points_label.text = "No places returned."


func _on_request_failed(endpoint: String, error: String) -> void:
	push_error("Backend request failed (%s): %s" % [endpoint, error])
	if g.map != null:
		var points_label := g.map.get_node_or_null("../UI/points") as Label
		if points_label != null:
			points_label.text = "Backend error (%s): %s" % [endpoint, error]


func submit_score(score: int) -> void:
	var res: Variant = await _request(HTTPClient.METHOD_POST, "/scores", {"score": score})
	score_submitted.emit(res is Dictionary and not res.is_empty())
