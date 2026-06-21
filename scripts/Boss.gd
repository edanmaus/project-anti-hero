extends CharacterBody2D

signal defeated

@export var PROJECTILE_SCENE = preload("res://scenes/Projectile.tscn")

@export var SPEED = 200.0
@export var GRAVITY = 980.0
@export var MAX_HEALTH: int = 300

@export var SWIPE_DAMAGE: int = 25

@export var SLAM_DAMAGE: int = 50
@export var SLAM_COOLDOWN: float = 2.0
@export var SLAM_WINDUP: float = 0.35
@export var SLAM_ACTIVE_TIME: float = 0.3

@export var PROJECTILE_COOLDOWN: float = 1.0

var health: int = MAX_HEALTH
var facing_direction: int = -1

var is_attacking: bool = false
var is_slamming: bool = false
var slam_cooldown: float = 0.0
var projectile_cooldown: float = 0.0

var game_over: bool = false

@onready var swipe_hitbox: Area2D = $SwipeHitbox
@onready var slam_hitbox: Area2D = $SlamHitbox

func _ready() -> void:
	swipe_hitbox.monitoring = false
	swipe_hitbox.visible = false
	slam_hitbox.monitoring = false
	slam_hitbox.visible = false
	swipe_hitbox.body_entered.connect(_swipe_collides)
	slam_hitbox.body_entered.connect(_slam_collides)

func _swipe_collides(body: Node2D) -> void:
	if not game_over:
		if body.name == "Hero" and body.has_method("take_damage"):
			body.take_damage(SWIPE_DAMAGE)

func _slam_collides(body: Node2D) -> void:
	if not game_over:
		if body.name == "Hero" and body.has_method("take_damage"):
			body.take_damage(SLAM_DAMAGE)

func _physics_process(delta: float) -> void:
	if game_over:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	var direction := 0
	if Input.is_action_pressed("move_left"):
		direction = -1
	elif Input.is_action_pressed("move_right"):
		direction = 1

	if direction != 0:
		facing_direction = direction

	velocity.x = direction * SPEED
	move_and_slide()

	if slam_cooldown > 0.0:
		slam_cooldown -= delta
	if projectile_cooldown > 0.0:
		projectile_cooldown -= delta

	# Light attack — blocked while Slam is running
	if Input.is_action_just_pressed("boss_light_attack") and not is_attacking and not is_slamming:
		perform_swipe()

	# Heavy attack — blocked while Swipe is running, must be off cooldown
	if Input.is_action_just_pressed("boss_heavy_attack") and not is_slamming and not is_attacking and slam_cooldown <= 0.0:
		perform_slam()

	# Ranged attack — blocked while Swipe or Slam is running, must be off cooldown
	if Input.is_action_just_pressed("boss_projectile") and projectile_cooldown <= 0.0 and not is_attacking and not is_slamming:
		perform_projectile()

func set_game_over() -> void:
	game_over = true
	velocity = Vector2.ZERO

func perform_swipe() -> void:
	is_attacking = true

	if facing_direction == 1:
		swipe_hitbox.position = Vector2(80, 10)
	else:
		swipe_hitbox.position = Vector2(-70, 10)

	swipe_hitbox.monitoring = true
	swipe_hitbox.visible = true

	await get_tree().process_frame
	await get_tree().process_frame

	await get_tree().create_timer(0.25).timeout

	swipe_hitbox.monitoring = false
	swipe_hitbox.visible = false
	is_attacking = false

func perform_slam() -> void:
	is_slamming = true
	slam_cooldown = SLAM_COOLDOWN

	if facing_direction == 1:
		slam_hitbox.position = Vector2(80, 5)
	else:
		slam_hitbox.position = Vector2(-130, 5)

	slam_hitbox.visible = true
	slam_hitbox.monitoring = false

	await get_tree().create_timer(SLAM_WINDUP).timeout

	if game_over:
		slam_hitbox.visible = false
		is_slamming = false
		return

	slam_hitbox.monitoring = true

	await get_tree().process_frame
	await get_tree().process_frame

	await get_tree().create_timer(SLAM_ACTIVE_TIME).timeout

	slam_hitbox.monitoring = false
	slam_hitbox.visible = false
	is_slamming = false

func perform_projectile() -> void:
	projectile_cooldown = PROJECTILE_COOLDOWN

	var proj = PROJECTILE_SCENE.instantiate()

	if facing_direction == 1:
		proj.global_position = global_position + Vector2(85, 40)
	else:
		proj.global_position = global_position + Vector2(-35, 40)

	proj.setup(facing_direction)
	get_parent().add_child(proj)

	print("Boss fired Dark Projectile!")

func take_damage(amount: int) -> void:
	if health <= 0:
		return

	health -= amount
	print("Boss took ", amount, " damage. Health: ", health, " / ", MAX_HEALTH)

	if health <= 0:
		health = 0
		print("The Boss has been defeated!")
		defeated.emit()
