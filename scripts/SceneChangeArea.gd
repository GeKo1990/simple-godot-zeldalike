@tool
extends Area2D

@export var size: Vector2 = Vector2(32, 32) :
	set(value):
		size = value
		if is_inside_tree():
			_update_shape()

@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	# Runs both in editor (because of @tool) and in game
	_ensure_shape()
	_update_shape()

func _ensure_shape() -> void:
	if collision == null:
		return

	if collision.shape == null:
		# First time: create a rectangle shape
		collision.shape = RectangleShape2D.new()
	else:
		# Make the shape unique per instance, but only in the editor
		# so resizing one doesn't resize all others
		if Engine.is_editor_hint():
			collision.shape = collision.shape.duplicate()

func _update_shape() -> void:
	_ensure_shape()
	if collision.shape is RectangleShape2D:
		var rect := collision.shape as RectangleShape2D
		rect.extents = size * 0.5
