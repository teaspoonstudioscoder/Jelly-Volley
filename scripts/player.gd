extends Node3D
class_name Blobby

## Ein Blob-Spieler — Bewegung links/rechts, Dauerfeuer-Sprung wie im Original.

@export var side: int = -1        # -1 = linke Hälfte, 1 = rechte Hälfte
@export var action_prefix: String = "p1"

const MOVE_SPEED := 7.0
const JUMP_VELOCITY := 13.0
const GRAVITY := 38.0
const HOLD_GRAVITY_FACTOR := 0.6  # Sprungtaste halten = weniger Schwerkraft im Aufstieg
const COURT_HALF := 7.4
const NET_MARGIN := 1.0

var velocity := Vector3.ZERO
var frozen := false

@onready var visual: Node3D = $Visual

func _physics_process(delta: float) -> void:
	var on_floor := position.y <= 0.001
	if frozen:
		velocity.x = 0.0
	else:
		var dir := Input.get_axis(action_prefix + "_left", action_prefix + "_right")
		velocity.x = dir * MOVE_SPEED
		if on_floor and Input.is_action_pressed(action_prefix + "_jump"):
			velocity.y = JUMP_VELOCITY
	var g := GRAVITY
	if not frozen and velocity.y > 0.0 and Input.is_action_pressed(action_prefix + "_jump"):
		g *= HOLD_GRAVITY_FACTOR
	velocity.y -= g * delta
	position += velocity * delta
	if position.y <= 0.0:
		position.y = 0.0
		if velocity.y < 0.0:
			velocity.y = 0.0
	if side < 0:
		position.x = clampf(position.x, -COURT_HALF, -NET_MARGIN)
	else:
		position.x = clampf(position.x, NET_MARGIN, COURT_HALF)
	position.z = 0.0
	# Squash & Stretch für den Wabbel-Look
	var s := 1.0
	if not on_floor:
		s = clampf(1.0 + velocity.y * 0.018, 0.82, 1.22)
	var target := Vector3(1.0 / sqrt(s), s, 1.0 / sqrt(s))
	visual.scale = visual.scale.lerp(target, minf(14.0 * delta, 1.0))

func collision_center() -> Vector3:
	return global_position + Vector3(0.0, 0.85, 0.0)

func reset_to(x: float) -> void:
	position = Vector3(x, 0.0, 0.0)
	velocity = Vector3.ZERO
	visual.scale = Vector3.ONE
