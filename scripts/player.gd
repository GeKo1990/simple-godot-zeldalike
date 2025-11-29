extends CharacterBody2D

const SPEED = 100.0

var current_direction: String = "front" # "front", "back", "side"

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	player_movement(delta)
	
func player_movement(delta) -> void:
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		velocity = input_vector * SPEED

		# Decide which direction we're facing
		if abs(input_vector.x) > abs(input_vector.y):
			# Side
			current_direction = "side"
			anim.flip_h = input_vector.x < 0
			anim.play("walk_side")
		elif input_vector.y > 0:
			# Down
			current_direction = "front"
			anim.play("walk_front")
		else:
			# Up
			current_direction = "back"
			anim.play("walk_back")
	else:
		# No input: idle anim based on last direction
		velocity = Vector2.ZERO
		match current_direction:
			"front":
				anim.play("idle_front")
			"back":
				anim.play("idle_back")
			"side":
				anim.play("idle_side")
			_:
				anim.play("idle_front") # fallback
		
	move_and_slide()
