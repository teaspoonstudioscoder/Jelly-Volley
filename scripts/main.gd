extends Node3D

## Spiellogik: Aufschlag, Berührungszählung, Punkte, Sieg.

const WIN_SCORE := 15
const MAX_TOUCHES := 3
const SERVE_X := 4.5

@onready var ball: VolleyBall = $Ball
@onready var blobs := {-1: $Player1, 1: $Player2}
@onready var score_left: Label = $HUD/Root/ScoreLeft
@onready var score_right: Label = $HUD/Root/ScoreRight
@onready var message: Label = $HUD/Root/Message
@onready var board_left: Label3D = $Board/ScoreLeft
@onready var board_right: Label3D = $Board/ScoreRight
@onready var crowd: MeshInstance3D = $Stadium/Stadium_Crowd
@onready var ambience: AudioStreamPlayer = $Ambience
@onready var cheer: AudioStreamPlayer = $Cheer
@onready var whistle: AudioStreamPlayer = $Whistle
@onready var hit_sound: AudioStreamPlayer = $HitSound

var crowd_mat: ShaderMaterial
var celebrate_tween: Tween

var score := {-1: 0, 1: 0}
var touches := {-1: 0, 1: 0}
var serving_side := -1
var rally_active := false
var game_over := false

func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	ball.players = [blobs[-1], blobs[1]]
	ball.touched.connect(_on_ball_touched)
	ball.hit_ground.connect(_on_ball_ground)
	_setup_crowd()
	# Die Loop-Flag aus der .import-Datei greift hier nicht zuverlaessig,
	# deshalb die Atmo formatunabhaengig neu anstossen.
	ambience.finished.connect(ambience.play)
	if not ambience.playing:
		ambience.play()
	_update_score()
	message.text = "Red: A/D + W       Blue: Arrow Keys\nFirst serve: Red"
	_start_serve(serving_side, 2.2)

func _process(_delta: float) -> void:
	if game_over and Input.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
	# ESC beendet das Spiel.
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		get_tree().quit()

func _start_serve(side: int, delay: float) -> void:
	touches = {-1: 0, 1: 0}
	rally_active = false
	blobs[-1].reset_to(-SERVE_X)
	blobs[1].reset_to(SERVE_X)
	ball.serve_at(SERVE_X * side)
	await get_tree().create_timer(delay).timeout
	if game_over:
		return
	message.text = ""
	rally_active = true
	ball.release()

func _on_ball_touched(side: int) -> void:
	if not rally_active:
		return
	hit_sound.pitch_scale = randf_range(0.92, 1.1)
	hit_sound.play()
	touches[side] += 1
	touches[-side] = 0
	if touches[side] > MAX_TOUCHES:
		_award_point(-side, "Too many touches!")

func _on_ball_ground(side: int) -> void:
	if not rally_active:
		return
	_award_point(-side, "")

func _award_point(side: int, reason: String) -> void:
	if not rally_active or game_over:
		return
	rally_active = false
	ball.dead = true
	score[side] += 1
	_update_score()
	_celebrate()
	var winner_name := "Red" if side < 0 else "Blue"
	var prefix := "" if reason == "" else reason + "\n"
	if score[side] >= WIN_SCORE:
		game_over = true
		ball.frozen = true
		message.text = prefix + winner_name + " wins the match!\n[Enter] for a rematch"
		return
	serving_side = side
	message.text = prefix + "Point for " + winner_name
	_start_serve(side, 1.4)

func _update_score() -> void:
	score_left.text = str(score[-1])
	score_right.text = str(score[1])
	board_left.text = str(score[-1])
	board_right.text = str(score[1])

func _setup_crowd() -> void:
	# Zur Laufzeit setzen: Overrides auf Knoten innerhalb der instanzierten
	# glTF-Szene überleben das Speichern der Szene nicht.
	crowd_mat = ShaderMaterial.new()
	crowd_mat.shader = load("res://shaders/crowd.gdshader")
	crowd_mat.set_shader_parameter("excite", 0.0)
	crowd.material_override = crowd_mat

func _celebrate() -> void:
	whistle.play()
	cheer.play()
	# Die Menge wird kurz lauter, dann zurueck auf Grundpegel
	ambience.volume_db = -9.0
	var vol := create_tween()
	vol.tween_property(ambience, "volume_db", -16.0, 3.0).set_delay(1.0)
	if crowd_mat == null:
		return
	if celebrate_tween != null and celebrate_tween.is_valid():
		celebrate_tween.kill()
	crowd_mat.set_shader_parameter("excite", 1.0)
	celebrate_tween = create_tween()
	celebrate_tween.tween_interval(1.6)
	celebrate_tween.tween_property(crowd_mat, "shader_parameter/excite", 0.0, 1.8)
