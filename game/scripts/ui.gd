class_name UI
extends CanvasLayer

@onready var uianim: AnimationPlayer = $uianim
@onready var text_name: Label = $vbox/name_panel/name
@onready var text_desc: Label = $vbox/desk_panel/desc
@onready var poi_preview: TextureRect = $preview_container/POI_Preview

var _preview_request: HTTPRequest


func _ready() -> void:
	g.ui = self


func load_preview_from_url(url: String) -> void:
	# Cancel any in-flight request so an old image can't overwrite a newer one
	if _preview_request:
		_preview_request.cancel_request()
		_preview_request.queue_free()

	_preview_request = HTTPRequest.new()
	add_child(_preview_request)

	var err := _preview_request.request(url)
	if err != OK:
		push_error("POI preview request failed: %s" % err)
		_preview_request.queue_free()
		_preview_request = null
		return

	var req := _preview_request
	var result = await req.request_completed

	# If this request was replaced while waiting, ignore the result
	if req != _preview_request:
		return

	_preview_request.queue_free()
	_preview_request = null

	var code: int = result[1]
	var headers: PackedStringArray = result[2]
	var body: PackedByteArray = result[3]

	if result[0] != HTTPRequest.RESULT_SUCCESS or code != 200:
		push_error("POI preview download failed (code %d)" % code)
		return

	var image := _bytes_to_image(body, headers, url)
	if image == null:
		push_error("POI preview: unsupported or invalid image")
		return

	poi_preview.texture = ImageTexture.create_from_image(image)


func _bytes_to_image(body: PackedByteArray, headers: PackedStringArray, url: String) -> Image:
	var image := Image.new()
	var err := ERR_FILE_UNRECOGNIZED

	# Try Content-Type first, then fall back to the URL extension
	var content_type := ""
	for h in headers:
		if h.to_lower().begins_with("content-type:"):
			content_type = h.substr(13).strip_edges().to_lower()
			break

	if content_type.contains("png") or url.get_extension().to_lower() == "png":
		err = image.load_png_from_buffer(body)
	elif content_type.contains("jpeg") or content_type.contains("jpg") \
			or url.get_extension().to_lower() in ["jpg", "jpeg"]:
		err = image.load_jpg_from_buffer(body)
	elif content_type.contains("webp") or url.get_extension().to_lower() == "webp":
		err = image.load_webp_from_buffer(body)

	# Last resort: try each format
	if err != OK:
		for loader in ["load_png_from_buffer", "load_jpg_from_buffer", "load_webp_from_buffer"]:
			if image.call(loader, body) == OK:
				err = OK
				break

	return image if err == OK else null
