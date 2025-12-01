extends CharacterBody2D

const SPEED = 100.0

signal health_changed(current: int, max: int)
signal died

var current_direction: String = "front" # "front", "back", "side"
var is_dead: bool = false
var is_attacking: bool = false
var facing_left: bool = false

@export var max_health: int = 6:
	set(value):
		max_health = max(value, 1)
		health = clamp(health, 0, max_health)
		health_changed.emit(health, max_health)

@export var health: int = 6:
	set(value):
		health = clamp(value, 0, max_health)
		health_changed.emit(health, max_health)

		if health == 0 and not is_dead:
			_die()

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

@onready var sword_hitbox: Area2D = $AnimatedSprite2D/SwordHitbox
@onready var slash_side_right: CollisionPolygon2D = $AnimatedSprite2D/SwordHitbox/SlashSideRight
@onready var slash_side_left: CollisionPolygon2D = $AnimatedSprite2D/SwordHitbox/SlashSideLeft
@onready var slash_front: CollisionPolygon2D = $AnimatedSprite2D/SwordHitbox/SlashFront
@onready var slash_back: CollisionPolygon2D = $AnimatedSprite2D/SwordHitbox/SlashBack

func _ready() -> void:
	health_changed.emit(health, max_health)

func _physics_process(_delta: float) -> void:
	if is_dead:
		return
		
	if Input.is_action_just_pressed("primary_attack") and not is_attacking:
		_start_attack()
		
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	_movement()
	move_and_slide()
	
func _start_attack() -> void:
	is_attacking = true
	velocity = Vector2.ZERO
	
	match current_direction:
		"front":
			anim.flip_h = false
			anim.play("attack_front")
		"back":
			anim.flip_h = false
			anim.play("attack_back")
		"side":
			anim.flip_h = facing_left
			anim.play("attack_side")
		_:
			anim.flip_h = false
			anim.play("attack_front")
	
func _movement() -> void:
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		velocity = input_vector * SPEED

		# Decide which direction we're facing
		if abs(input_vector.x) > abs(input_vector.y):
			# Side
			current_direction = "side"
			facing_left = input_vector.x < 0
			anim.flip_h = facing_left
			anim.play("walk_side")
		elif input_vector.y > 0:
			# Down
			current_direction = "front"
			anim.flip_h = false
			anim.play("walk_front")
		else:
			# Up
			current_direction = "back"
			anim.flip_h = false
			anim.play("walk_back")
	else:
		# No input: idle anim based on last direction
		velocity = Vector2.ZERO
		match current_direction:
			"front":
				anim.flip_h = false
				anim.play("idle_front")
			"back":
				anim.flip_h = false
				anim.play("idle_back")
			"side":
				anim.flip_h = facing_left
				anim.play("idle_side")
			_:
				anim.flip_h = false
				anim.play("idle_front") # fallback
			
func _disable_hitbox() -> void:
	slash_back.disabled = true
	slash_front.disabled = true
	slash_side_left.disabled = true
	slash_side_right.disabled = true
	slash_front.visible = false
	slash_side_right.visible = false
	slash_side_left.visible = false
	slash_back.visible = false
	sword_hitbox.monitorable = false
	sword_hitbox.monitoring = false
	sword_hitbox.visible = false

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation.begins_with("attack_"):
		is_attacking = false
		_disable_hitbox()

func _on_animated_sprite_2d_frame_changed() -> void:
	if not anim.animation.begins_with("attack_"):
		_disable_hitbox()
		return
		
	var frame := anim.frame
	_disable_hitbox()
	
	# Hit frame is always frame 1
	if frame == 1:
		match current_direction:
			"front":
				slash_front.disabled = false
				slash_front.visible = true
			"back":
				slash_back.disabled = false
				slash_back.visible = true
			"side":
				if facing_left:
					slash_side_left.disabled = false
					slash_side_left.visible = true
				else:
					slash_side_right.disabled = false
					slash_side_right.visible = true
			
		sword_hitbox.monitorable = true
		sword_hitbox.monitoring = true
		sword_hitbox.visible = true
		
func _take_damage(amount: int) -> void:
	if is_dead:
		return
	health -= amount
	
func _heal(amount: int) -> void:
	if is_dead:
		return
	health += amount
	
func _die():
	is_dead = true
	anim.play("death")
	died.emit()
	
func _on_hurt_box_area_entered(_area: Area2D) -> void:
	_take_damage(1)
