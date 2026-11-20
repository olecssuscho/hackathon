extends Node

const START_LAT := 49.588159996485764
const START_LON := 34.551463768772415
const TILE := 16             # one grid cell, in pixels
const TILE_PX := 256         # one map tile, in pixels
const CELLS_PER_TILE := 16
const ZOOM := 18

var origin_tile := Vector2i.ZERO   # map tile the game starts in (chunk 0,0)
var start_cell := Vector2i.ZERO    # cell inside that tile where the lat/lon falls

var ui: UI

func _ready() -> void:
	var f := latlon_to_tile_f(START_LAT, START_LON, ZOOM)
	origin_tile = Vector2i(f.floor())
	start_cell = Vector2i(((f - Vector2(origin_tile)) * CELLS_PER_TILE).floor())
	print("origin tile: ", origin_tile, "  start cell: ", start_cell)


## Fractional tile coordinates, so the position inside the tile is kept.
func latlon_to_tile_f(lat: float, lon: float, z: int) -> Vector2:
	var n := pow(2.0, z)
	var x := (lon + 180.0) / 360.0 * n
	var y := (1.0 - asinh(tan(deg_to_rad(lat))) / PI) / 2.0 * n
	return Vector2(x, y)

## lat/lon -> in-game world position (pixels)
func latlon_to_world(lat: float, lon: float) -> Vector2:
	var f := latlon_to_tile_f(lat, lon, ZOOM)
	return (f - Vector2(origin_tile)) * TILE_PX


## in-game world position (pixels) -> Vector2(lat, lon)
func world_to_latlon(pos: Vector2) -> Vector2:
	var n := pow(2.0, ZOOM)
	var t := pos / TILE_PX + Vector2(origin_tile)
	var lon := t.x / n * 360.0 - 180.0
	var lat := rad_to_deg(atan(sinh(PI * (1.0 - 2.0 * t.y / n))))
	return Vector2(lat, lon)


## in-game world position -> grid cell (same cells the player uses)
func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i((pos / TILE).floor())

var placed := {}   

func place(node: Node2D, lat: float, lon: float, snap_to_grid := false, id := "") -> Node2D:
	var pos := g.latlon_to_world(lat, lon)
	if snap_to_grid:
		var cell := g.world_to_cell(pos)
		pos = Vector2(cell * g.TILE) + Vector2.ONE * (g.TILE * 0.5)   # centre of that cell
	node.position = pos
	add_child(node)
	if id != "":
		if placed.has(id):
			placed[id].queue_free()   # replace an earlier node with the same id
		placed[id] = node
	return node

func place_scene(scene: PackedScene, lat: float, lon: float, snap_to_grid := false, id := "") -> Node2D:
	return place(scene.instantiate() as Node2D, lat, lon, snap_to_grid, id)
	

const POI_SCENE: PackedScene = preload("uid://5ywdyvi6y0cy")


func add_poi(lat: float, lon: float, poi_name := "Name",
		poi_description := "Description",
		poi_img := "https://i.nuuls.com/St4DS.png", id := "") -> Node2D:
	var poi = POI_SCENE.instantiate()   # untyped on purpose, so the exported vars can be set
	poi.poi_name = poi_name
	poi.poi_description = poi_description
	poi.poi_img = poi_img
	return place(poi, lat, lon, false, id)
