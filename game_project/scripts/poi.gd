extends Node2D

@onready var map: Node = get_tree().get_first_node_in_group("map")

@export var poi_name: String = "Name"
@export_multiline() var poi_description: String = "Description"
@export var poi_img: String = "https://i.nuuls.com/St4DS.png"

func _ready() -> void:
	visible = false
	_set_interactive(false)
	map.chunk_discovered.connect(_on_chunk_discovered)
	_check.call_deferred()   # deferred, so the position is final even if it's set after add_child


func _check() -> void:
	if map.is_discovered(global_position):
		_unlock(false)   # tile was already there (e.g. loaded from the save), so no fade


func _on_chunk_discovered(c: Vector2i) -> void:
	if not visible and c == map.chunk_of(global_position):
		_unlock(true)


func _unlock(animate: bool) -> void:
	visible = true
	if animate:
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.4)   # same duration as the tile fade
	else:
		modulate.a = 1.0
	_set_interactive(true)


func _set_interactive(on: bool) -> void:
	if has_node("Area2D"):
		$Area2D.set_deferred("monitoring", on)
		$Area2D.set_deferred("monitorable", on)


func _on_interaction_body_entered(body: Node2D) -> void:
	if body is Player:
		g.ui.text_name.text = poi_name
		g.ui.text_desc.text  = poi_description
		g.ui.load_preview_from_url(poi_img)
		g.dialogue_open = true


func _on_interaction_body_exited(body: Node2D) -> void:
	if body is Player:
		pass
