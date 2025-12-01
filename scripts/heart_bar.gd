extends Control

@export var health_per_heart: int = 2
@export var tex_heart_empty: Texture2D
@export var tex_heart_half: Texture2D
@export var tex_heart_full: Texture2D

@onready var container: HBoxContainer = $MarginContainer/HBoxContainer
@onready var heart_template: TextureRect = $MarginContainer/HBoxContainer/HeartTemplate

var _max_hearts: int = 0
var _hearts: Array[TextureRect] = []

func _ready() -> void:
	# Template is only for layout in editor, hide it in game
	heart_template.visible = false

func set_max_health(max_health: int) -> void:
	_max_hearts = int(ceil(float(max_health) / float(health_per_heart)))
	_build_hearts()

func set_health(current: int, max_health: int) -> void:
	if _max_hearts == 0:
		set_max_health(max_health)
	_update_hearts(current)

func _build_hearts() -> void:
	# Remove old runtime hearts (but not the template)
	for h in _hearts:
		if is_instance_valid(h):
			h.queue_free()
	_hearts.clear()

	# Create new hearts from the template
	for i in _max_hearts:
		var heart := heart_template.duplicate()
		heart.visible = true
		heart.texture = tex_heart_empty
		container.add_child(heart)
		_hearts.append(heart)

func _update_hearts(current_health: int) -> void:
	var health_left := current_health
	for heart in _hearts:
		if health_left >= health_per_heart:
			heart.texture = tex_heart_full
		elif health_left > 0:
			heart.texture = tex_heart_half
		else:
			heart.texture = tex_heart_empty

		health_left -= health_per_heart
