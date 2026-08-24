extends Node3D
class_name VolleyBall

## Eigene Ballphysik im Blobby-Volley-Stil — konstante Abschlag-
## Geschwindigkeit vom Blob, Netzkante als runder Abpraller.

signal touched(side: int)
signal hit_ground(side: int)

const RADIUS := 0.45
const GRAVITY := 13.0
const HIT_SPEED := 12.5
const BLOB_RADIUS := 0.85
const COURT_HALF := 7.8
const NET_HALF_W := 0.12
const NET_TOP := 3.0
const MAX_SPEED := 18.0

var velocity := Vector3.ZERO
var frozen := true
var dead := false
var players: Array = []
var _touch_cooldown := {}

@onready var visual: Node3D = $Visual

func _physics_process(delta: float) -> void:
	if frozen:
		return
	velocity.y -= GRAVITY * delta
	position += velocity * delta
	position.z = 0.0

	if not dead:
		for p in players:
			_collide_blob(p)
	_collide_net()
	_collide_walls()
	_collide_floor()

	visual.rotate_z(-velocity.x * delta / RADIUS)

func _collide_blob(p: Blobby) -> void:
	var c: Vector3 = p.collision_center()
	var to_ball := position - c
	to_ball.z = 0.0
	var dist := to_ball.length()
	var min_dist := RADIUS + BLOB_RADIUS
	if dist < min_dist and dist > 0.001:
		var n := to_ball / dist
		position = c + n * (min_dist + 0.01)
		var now := Time.get_ticks_msec()
		if int(_touch_cooldown.get(p.side, 0)) <= now:
			velocity = n * HIT_SPEED + p.velocity * 0.4
			velocity = velocity.limit_length(MAX_SPEED)
			velocity.z = 0.0
			_touch_cooldown[p.side] = now + 150
			touched.emit(p.side)

func _collide_net() -> void:
	if position.y >= NET_TOP:
		# Netzkante als kleiner Kreis: erlaubt Abroller über die Kante
		var top := Vector3(0.0, NET_TOP, 0.0)
		var d := position - top
		d.z = 0.0
		var r := RADIUS + NET_HALF_W
		var dist := d.length()
		if dist < r and dist > 0.001:
			var n := d / dist
			position = top + n * r
			velocity = velocity.bounce(n) * 0.75
	elif absf(position.x) < NET_HALF_W + RADIUS:
		var push := signf(position.x)
		if push == 0.0:
			push = 1.0
		position.x = push * (NET_HALF_W + RADIUS)
		velocity.x = push * absf(velocity.x) * 0.7

func _collide_walls() -> void:
	if position.x > COURT_HALF - RADIUS:
		position.x = COURT_HALF - RADIUS
		velocity.x = -absf(velocity.x) * 0.8
	elif position.x < -(COURT_HALF - RADIUS):
		position.x = -(COURT_HALF - RADIUS)
		velocity.x = absf(velocity.x) * 0.8

func _collide_floor() -> void:
	if position.y < RADIUS:
		position.y = RADIUS
		if velocity.y < 0.0:
			velocity.y = absf(velocity.y) * 0.55
		velocity.x *= 0.85
		if not dead:
			dead = true
			hit_ground.emit(-1 if position.x < 0.0 else 1)

func serve_at(x: float) -> void:
	position = Vector3(x, 4.0, 0.0)
	velocity = Vector3.ZERO
	frozen = true
	dead = false
	_touch_cooldown.clear()

func release() -> void:
	frozen = false
