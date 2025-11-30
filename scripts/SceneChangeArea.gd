@tool
extends Area2D

# --- EDITOR: SIZE / SHAPE -----------------------------------------------------

@export var size: Vector2 = Vector2(32, 32) :
	set(value):
		size = value
		if is_inside_tree():
			_update_shape()

@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Editor + game
	_ensure_shape()
	_update_shape()

	# Only connect gameplay logic at runtime, not in editor
	if not Engine.is_editor_hint():
		self.body_entered.connect(_on_body_entered)


func _ensure_shape() -> void:
	if collision == null:
		return

	if collision.shape == null:
		# First time: create a rectangle shape
		collision.shape = RectangleShape2D.new()
	else:
		# Make the shape unique per instance in the editor
		if Engine.is_editor_hint():
			collision.shape = collision.shape.duplicate()


func _update_shape() -> void:
	_ensure_shape()
	if collision.shape is RectangleShape2D:
		var rect := collision.shape as RectangleShape2D
		rect.extents = size * 0.5


# --- GAMEPLAY: SCENE CHANGE LOGIC --------------------------------------------

@export_file("*.tscn") var target_scene: String
@export var target_spawn_point: String = ""
@export var one_shot: bool = false

var _already_triggered: bool = false


func _on_body_entered(body: Node2D) -> void:
	if Engine.is_editor_hint():
		return

	if not body.is_in_group("player"):
		return

	if one_shot and _already_triggered:
		return

	if target_scene == "":
		push_warning("SceneChangeArea: target_scene is empty.")
		return

	_already_triggered = true
	GameManager.change_level(target_scene, target_spawn_point)
