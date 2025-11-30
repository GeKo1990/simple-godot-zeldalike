extends CharacterBody2D

# -------------------------------------------------------------------
# CONFIG
# -------------------------------------------------------------------
const SPEED               := 25.0
const WANDER_RADIUS       := 64.0
const ARRIVE_THRESHOLD    := 4.0

const ATTACK_RANGE        := 48.0      # how close before we jump (center-to-center)
const ATTACK_COOLDOWN_MS  := 1000     # time between jumps in ms
const ATTACK_SPEED        := 80
const ATTACK_STOP_DISTANCE := 4.0      # how close to target before we stop

const MAX_HEALTH          := 100

# -------------------------------------------------------------------
# STATE
# -------------------------------------------------------------------
enum State { IDLE, WANDER, CHASE, ATTACK, DEAD }

var state: State = State.WANDER

var health: int = MAX_HEALTH
var current_direction: String = "front"

var attack_target: Vector2
var wander_target: Vector2
var start_position: Vector2
var attack_cooldown_until: int = 0

var player: Node2D = null   # set from DetectionArea

# -------------------------------------------------------------------
# NODES
# -------------------------------------------------------------------
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: CollisionShape2D = $CollisionShape2D # slime body collision

# -------------------------------------------------------------------
# LIFE CYCLE
# -------------------------------------------------------------------
func _ready() -> void:
	start_position = global_position
	randomize()
	_pick_new_wander_target()
	_set_state(State.WANDER)

func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			_update_idle(delta)
		State.WANDER:
			_update_wander(delta)
		State.CHASE:
			_update_chase(delta)
		State.ATTACK:
			_update_attack(delta)
		State.DEAD:
			return  # no movement / logic when dead

	move_and_slide()

# -------------------------------------------------------------------
# STATE MACHINE
# -------------------------------------------------------------------
func _set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state

	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			_play_idle()
		State.WANDER:
			velocity = Vector2.ZERO
			_pick_new_wander_target()
			_play_idle()
		State.CHASE:
			# nothing special, handled in _update_chase
			pass
		State.ATTACK:
			_enter_attack_state()
		State.DEAD:
			_enter_dead_state()

# -------------------------------------------------------------------
# STATE UPDATES
# -------------------------------------------------------------------
func _update_idle(_delta: float) -> void:
	velocity = Vector2.ZERO
	_play_idle()
	# You could add an idle timer here and then switch back to wander

func _update_wander(_delta: float) -> void:
	var to_target := wander_target - global_position
	if to_target.length() < ARRIVE_THRESHOLD:
		velocity = Vector2.ZERO
		_play_idle()
		_pick_new_wander_target()
	else:
		var dir := to_target.normalized()
		velocity = dir * (SPEED * 0.5)
		_update_direction_and_animation(dir, true)

func _update_chase(_delta: float) -> void:
	if player == null:
		_set_state(State.WANDER)
		return

	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var now := Time.get_ticks_msec()
	
	# Try to attack if close enough and cooldown ready
	if dist <= ATTACK_RANGE and now >= attack_cooldown_until:
		_set_state(State.ATTACK)
		return

	# Otherwise chase
	var dir := to_player.normalized()
	velocity = dir * SPEED
	_update_direction_and_animation(dir, true)

func _update_attack(_delta: float) -> void:
	var to_target := attack_target - global_position
	if to_target.length() <= ATTACK_STOP_DISTANCE:
		velocity = Vector2.ZERO
		_play_idle()

		# Decide what to do after attack:
		if player != null:
			_set_state(State.CHASE)
		else:
			_set_state(State.WANDER)
	else:
		var dir := to_target.normalized()
		velocity = dir * ATTACK_SPEED
		_update_direction_and_animation(dir, true)

# -------------------------------------------------------------------
# STATE ENTER HELPERS
# -------------------------------------------------------------------
func _enter_attack_state() -> void:
	# Set cooldown
	attack_cooldown_until = Time.get_ticks_msec() + ATTACK_COOLDOWN_MS

	# Lock in the target position at start of jump
	if player != null:
		attack_target = player.global_position
	else:
		# no player? just bail out into wander
		_set_state(State.WANDER)
		return

	var dir := (attack_target - global_position)
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
		
	dir = dir.normalized()
	velocity = dir * ATTACK_SPEED

	_update_direction_and_animation(dir, true)

	match current_direction:
		"front":
			anim.play("attack_front")
		"back":
			anim.play("attack_back")
		"side":
			anim.play("attack_side")
		_:
			anim.play("attack_front")

func _enter_dead_state() -> void:
	velocity = Vector2.ZERO
	anim.play("death")
	hitbox.set_deferred("disabled", true)
	detection_area.set_deferred("monitorable", false)
	detection_area.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	hurtbox.set_deferred("monitoring", false)

# -------------------------------------------------------------------
# COMMON MOVEMENT / ANIMATION HELPERS
# -------------------------------------------------------------------
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

# -------------------------------------------------------------------
# SIGNALS: DETECTION AREA (AGGRO)
# -------------------------------------------------------------------
func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and state != State.DEAD:
		player = body
		_set_state(State.CHASE)

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		if state != State.DEAD and state != State.ATTACK:
			_set_state(State.WANDER)

# -------------------------------------------------------------------
# SIGNALS: HURTBOX (DAMAGE)
# -------------------------------------------------------------------
func _on_hurtbox_area_entered(area: Area2D) -> void:
	print("hit!")
	if area.is_in_group("player_hitbox"):
		_take_dmg(100)

func _take_dmg(amount: int) -> void:
	if state == State.DEAD:
		return

	health -= amount
	print("slime hp: ", health)

	if health <= 0:
		_set_state(State.DEAD)

# -------------------------------------------------------------------
