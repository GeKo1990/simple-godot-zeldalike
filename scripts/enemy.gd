extends CharacterBody2D

const SPEED = 50
const WANDER_RADIUS = 64.0
const ARRIVE_THRESHOLD = 4.0

var chase_player:bool = false
var wander_target: Vector2
var start_position: Vector2
var current_direction: String = "front"
var is_dead: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var hitbox: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	start_position = global_position
	randomize()
	_pick_new_wander_target()
	
func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if chase_player:
		_chase_player()
	else:
		_wander()
	
	move_and_slide()
	
func _chase_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		velocity = Vector2.ZERO
		_play_idle()
		return
	
	var dir := (player.global_position - global_position)
	if dir.length() > 1.0:
		dir = dir.normalized()
		velocity = dir * SPEED
		_update_direction_and_animation(dir, true)
	else:
		velocity = Vector2.ZERO
		_play_idle()
		
func _wander() -> void:
	var to_target := wander_target - global_position
	if to_target.length() < ARRIVE_THRESHOLD:
		# Reached target -> idle & choose a new one
		velocity = Vector2.ZERO
		_play_idle()
		_pick_new_wander_target()
	else:
		var dir := to_target.normalized()
		velocity = dir * (SPEED * 0.5)
		_update_direction_and_animation(dir, true)

func _pick_new_wander_target() -> void:
	var angle := randf() * TAU
	var distance := randf() * WANDER_RADIUS
	wander_target = start_position + Vector2(cos(angle), sin(angle)) * distance
	
func _update_direction_and_animation(dir: Vector2, is_moving: bool) -> void:
	if abs(dir.x) > abs(dir.y):
		current_direction = "side"
		anim.flip_h = dir.x < 0
		if is_moving:
			anim.play("walk_side")
		else:
			anim.play("idle_side")
	elif dir.y > 0:
		current_direction = "front"
		if is_moving:
			anim.play("walk_front")
		else:
			anim.play("idle_front")	
	else:
		current_direction = "back"
		if is_moving:
			anim.play("walk_back")
		else:
			anim.play("idle_back")
			
func _play_idle() -> void:
	match current_direction:
		"front":
			anim.play("idle_front")
		"back":
			anim.play("idle_back")
		"side":
			anim.play("idle_side")
		_:
			anim.play("idle_front")
			
# --- SIGNALS FROM DETECTION AREA ---------------------------------------------
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		chase_player = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		chase_player = false
		_pick_new_wander_target()
	

# --- DEATH --------------------------------------------------------------------
func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	anim.play("death")
	hitbox.disabled = true
	detection_area.monitoring = false
	detection_area.monitorable = false
