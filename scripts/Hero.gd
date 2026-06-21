extends CharacterBody2D

signal defeated

@export var GRAVITY = 980.0
@export var SPAWN_POSITION = Vector2(172, 448)
@export var ATTACK_RANGE: float = 70.0
@export var STOP_DISTANCE: float = 65.0

@export var LUNGE_DAMAGE: int = 18
@export var LUNGE_COOLDOWN: float = 3.0
@export var LUNGE_DURATION: float = 0.25
@export var LUNGE_SPEED: float = 450.0
@export var LUNGE_RANGE: float = 220.0

# These start at base values and are updated by GameManager on each respawn
@export var max_health: int = 100
@export var move_speed: int = 80
@export var attack_damage: int = 10
@export var attack_cooldown_duration: float = 1.5

var health: int = max_health
var is_dead: bool = false
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var lunge_unlocked: bool = false
var is_lunging: bool = false
var lunge_cooldown: float = 0.0
var game_over: bool = false

@onready var boss = $"../Boss"
@onready var strike_hitbox: Area2D = $StrikeHitbox
@onready var lunge_hitbox: Area2D = $LungeHitbox

func _ready() -> void:
	strike_hitbox.monitoring = false
	strike_hitbox.visible = false
	lunge_hitbox.monitoring = false
	lunge_hitbox.visible = false
	strike_hitbox.body_entered.connect(_strike_collides)
	lunge_hitbox.body_entered.connect(_lunge_collides)

func _strike_collides(body: Node2D) -> void:
	if not game_over and not is_dead:
		if body.name == "Boss" and body.has_method("take_damage"):
			body.take_damage(attack_damage)

func _lunge_collides(body: Node2D) -> void:
	if not game_over and not is_dead:
		if body.name == "Boss" and body.has_method("take_damage"):
			body.take_damage(LUNGE_DAMAGE)

func _physics_process(delta: float) -> void:
	if is_dead or game_over:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	if lunge_cooldown > 0.0:
		lunge_cooldown -= delta

	var distance_to_boss: float = abs(boss.position.x - position.x)

	if is_lunging:
		var lunge_dir: float = sign(boss.position.x - position.x)
		velocity.x = lunge_dir * LUNGE_SPEED
	else:
		if distance_to_boss > STOP_DISTANCE:
			var direction: float = sign(boss.position.x - position.x)
			velocity.x = direction * move_speed
		else:
			velocity.x = 0

		if lunge_unlocked and not is_attacking and lunge_cooldown <= 0.0 and distance_to_boss > ATTACK_RANGE and distance_to_boss <= LUNGE_RANGE:
			perform_lunge()
		elif distance_to_boss <= ATTACK_RANGE and attack_cooldown <= 0.0 and not is_attacking:
			perform_strike()

	move_and_slide()

func set_game_over() -> void:
	game_over = true
	velocity = Vector2.ZERO

func perform_strike() -> void:
	is_attacking = true
	attack_cooldown = attack_cooldown_duration

	var direction_to_boss: float = sign(boss.position.x - position.x)
	if direction_to_boss >= 0:
		strike_hitbox.position = Vector2(60, 5)
	else:
		strike_hitbox.position = Vector2(-60, 5)

	strike_hitbox.monitoring = true
	strike_hitbox.visible = true

	await get_tree().process_frame
	await get_tree().process_frame

	await get_tree().create_timer(0.2).timeout

	strike_hitbox.monitoring = false
	strike_hitbox.visible = false
	is_attacking = false

func perform_lunge() -> void:
	is_lunging = true
	lunge_cooldown = LUNGE_COOLDOWN

	var lunge_dir: float = sign(boss.position.x - position.x)
	if lunge_dir >= 0:
		lunge_hitbox.position = Vector2(60, 5)
	else:
		lunge_hitbox.position = Vector2(-80, 5)

	lunge_hitbox.monitoring = true
	lunge_hitbox.visible = true

	await get_tree().create_timer(LUNGE_DURATION).timeout

	await get_tree().process_frame
	await get_tree().process_frame

	lunge_hitbox.monitoring = false
	lunge_hitbox.visible = false
	is_lunging = false

func take_damage(amount: int) -> void:
	if is_dead or game_over:
		return

	health -= amount
	print("Hero took ", amount, " damage. Health: ", health, " / ", max_health)

	if health <= 0:
		health = 0
		die()

func die() -> void:
	is_dead = true
	is_lunging = false
	lunge_hitbox.monitoring = false
	lunge_hitbox.visible = false
	velocity = Vector2.ZERO
	print("The Hero has been defeated!")
	defeated.emit()

func respawn(new_max_health: int, new_move_speed: int, new_attack_damage: int, new_attack_cooldown: float) -> void:
	max_health = new_max_health
	health = max_health
	move_speed = new_move_speed
	attack_damage = new_attack_damage
	attack_cooldown_duration = new_attack_cooldown
	position = SPAWN_POSITION
	velocity = Vector2.ZERO
	is_dead = false
	attack_cooldown = 0.0
	is_lunging = false
	lunge_cooldown = 0.0
	lunge_hitbox.monitoring = false
	lunge_hitbox.visible = false

	print(
		"Hero respawned! HP: ", health,
		" | Speed: ", move_speed,
		" | Damage: ", attack_damage,
		" | Cooldown: ", "%.2f" % attack_cooldown_duration, "s"
	)
