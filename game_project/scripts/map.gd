class_name Map
extends Node2D

signal chunk_discovered(chunk: Vector2i)

const TILE_URL := "https://tile.openstreetmap.org/%d/%d/%d.png"
const USER_AGENT := "fogofdiscovery/0.1 (contact: neluba.artem1@gmail.com)"
const MAX_PARALLEL := 4
const REVEAL_RADIUS := 0    # 0 = only the tile you stand in, 1 = 3x3 tiles
const SAVE_PATH := "user://discovered.json"

var revealed := {}          # chunks requested (including ones still loading)
var discovered := {}        # chunks whose tile image actually loaded
var queue: Array[Vector2i] = []
var active := 0
var _poi_nodes: Array[Node2D] = []



const SHOW_GRID := true

var grid: GridOverlay

@export var pois: Array[POIData] = []
@onready var points: Label = $"../UI/points"


func _ready() -> void:
	add_to_group("map")
	g.map = self
	RenderingServer.set_default_clear_color(Color("6d7486ff"))   # fog colour

	_load_pois()
	for POIData in pois:
		points.text += "\n" + str(POIData.latitude) + " " + str(POIData.longitude)
	load_discovered()
	if SHOW_GRID:
		grid = GridOverlay.new()
		grid.tile_px = g.TILE_PX
		grid.z_index = -5
		add_child(grid)


func _load_pois() -> void:
	for p in pois:
		if p == null:
			continue   # empty slot in the inspector
		_poi_nodes.append(g.add_poi(
			p.latitude, p.longitude, p.poi_name, p.description, p.image_url
		))


func set_pois(new_pois: Array[POIData]) -> void:
	for poi_node in _poi_nodes:
		if is_instance_valid(poi_node):
			poi_node.queue_free()
	_poi_nodes.clear()
	pois = new_pois
	_load_pois()


func chunk_of(world_pos: Vector2) -> Vector2i:
	return Vector2i((world_pos / g.TILE_PX).floor())


func is_discovered(world_pos: Vector2) -> bool:
	return discovered.has(chunk_of(world_pos))


func reveal_around(world_pos: Vector2) -> void:
	var c := chunk_of(world_pos)
	if grid:
		grid.center = c
		grid.queue_redraw()
	for dy in range(-REVEAL_RADIUS, REVEAL_RADIUS + 1):
		for dx in range(-REVEAL_RADIUS, REVEAL_RADIUS + 1):
			var k := c + Vector2i(dx, dy)
			if not revealed.has(k):
				revealed[k] = true
				queue.append(k)
	_pump()


func _pump() -> void:
	while active < MAX_PARALLEL and not queue.is_empty():
		_fetch(queue.pop_front())


func _fetch(c: Vector2i) -> void:
	var t := g.origin_tile + c
	var req := HTTPRequest.new()
	add_child(req)
	active += 1
	req.request_completed.connect(_on_done.bind(req, c))

	var headers: PackedStringArray = []
	if not OS.has_feature("web"):
		headers.append("User-Agent: " + USER_AGENT)   # browsers forbid setting this

	var err := req.request(TILE_URL % [g.ZOOM, t.x, t.y], headers)
	if err != OK:
		_finish(req, c, false)


func _on_done(result: int, code: int, _headers: PackedStringArray,
		body: PackedByteArray, req: HTTPRequest, c: Vector2i) -> void:
	var ok := false
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var img := Image.new()
		if img.load_png_from_buffer(body) != OK:
			if img.load_jpg_from_buffer(body) != OK:
				img.load_webp_from_buffer(body)
		if not img.is_empty():
			_show_tile(c, img)
			ok = true
	_finish(req, c, ok)


func _finish(req: HTTPRequest, c: Vector2i, ok: bool) -> void:
	req.queue_free()
	active -= 1
	if not ok:
		revealed.erase(c)   # retried the next time the player enters this tile
	_pump()


func _show_tile(c: Vector2i, img: Image) -> void:
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(img)
	spr.centered = false
	spr.position = Vector2(c) * g.TILE_PX
	spr.z_index = -10
	spr.modulate.a = 0.0
	add_child(spr)
	create_tween().tween_property(spr, "modulate:a", 1.0, 0.4)

	discovered[c] = true
	chunk_discovered.emit(c)
	save_discovered()


# ---------------- saving ----------------

func save_discovered() -> void:
	var tiles := []
	for c in discovered:
		var t: Vector2i = g.origin_tile + c
		tiles.append([t.x, t.y])
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"zoom": g.ZOOM, "tiles": tiles}))


func load_discovered() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY or data.get("zoom", -1) != g.ZOOM:
		return   # a different zoom means different tiles, so ignore the old save
	for t in data.get("tiles", []):
		var c := Vector2i(int(t[0]), int(t[1])) - g.origin_tile
		if not revealed.has(c):
			revealed[c] = true
			queue.append(c)
	_pump()

class GridOverlay extends Node2D:
	var center := Vector2i.ZERO
	var radius := 4                       # tiles shown in each direction
	var tile_px := 256.0
	var color := Color(1, 1, 1, 0.35)

	func _draw() -> void:
		var lo := Vector2(center - Vector2i(radius, radius)) * tile_px
		var hi := Vector2(center + Vector2i(radius + 1, radius + 1)) * tile_px
		for i in range(-radius, radius + 2):
			var x := (center.x + i) * tile_px
			var y := (center.y + i) * tile_px
			draw_line(Vector2(x, lo.y), Vector2(x, hi.y), color, -1.0)
			draw_line(Vector2(lo.x, y), Vector2(hi.x, y), color, -1.0)
