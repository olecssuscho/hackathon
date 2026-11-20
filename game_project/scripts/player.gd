class_name Player
extends CharacterBody2D

const SPEED := 120.0         # pixels per second
const STOP_DISTANCE := 2.0   # stop when this close to the cursor (pixels)

var cell := Vector2i.ZERO
var chunk := Vector2i(999999, 999999)

@onready var coordinates: Label = $"../UI/Label"
@onready var map: Node = $"../Map"
@onready var anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	position = Vector2(g.start_cell * g.TILE) + Vector2.ONE * (g.TILE * 0.5)
	_update_grid()


func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var step := SPEED * delta

	if dir == Vector2.ZERO and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var to_mouse := get_global_mouse_position() - global_position
		var dist := to_mouse.length()
		if dist > STOP_DISTANCE:
			dir = to_mouse / dist
			step = minf(step, dist)   # don't overshoot the cursor

	if dir == Vector2.ZERO:
		anim.play("idle")
		return
		
	anim.play("walking")
	global_position += dir * step
	_update_grid()


func _update_grid() -> void:
	cell = Vector2i((global_position / g.TILE).floor())
	coordinates.text = "%d %d" % [cell.x, cell.y]

	var c := Vector2i((global_position / g.TILE_PX).floor())
	if c != chunk:
		chunk = c
		map.reveal_around(global_position)
