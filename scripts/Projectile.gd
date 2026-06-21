extends Area2D

const SPEED: float = 500.0
const DAMAGE: int = 20
const LIFETIME: float = 2.0

var direction: int = 1 # 1 = moving right, -1 = moving left
var time_alive: float = 0.0

func _ready() -> void:
	# Connect the signal that fires when a physics body enters this area
	body_entered.connect(_on_body_entered)

func setup(dir: int) -> void:
	# Boss calls this right after spawning the projectile to set direction
	direction = dir

func _physics_process(delta: float) -> void:
	# Move horizontally every frame
	position.x += direction * SPEED * delta

	# Destroy self after lifetime expires (in case nothing was hit)
	time_alive += delta
	if time_alive >= LIFETIME:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# Only damage the Hero — ignore Boss, walls, and everything else
	if body.name == "Hero" and body.has_method("take_damage"):
		body.take_damage(DAMAGE)
		queue_free()
		return

	# Disappear when hitting arena walls or floor (they are StaticBody2D)
	if body is StaticBody2D:
		queue_free()
