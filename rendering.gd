extends Node
class_name Renderer

var camQuat := Quaternion.IDENTITY
var pos := Quaternion(0,0,0,0)
const SENSITIVITY := 1.0/250
const MOVE_SPEED := 5.0
const ROLL_SPEED := 1.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var dir = event.screen_relative * SENSITIVITY
		dir = Vector3.RIGHT*dir.x + Vector3.DOWN*dir.y + Vector3.FORWARD
		camQuat = camQuat * Quaternion(Vector3.FORWARD, dir.normalized())
	elif event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("quit"):
		get_tree().quit()

func viewportChanged() -> void:
	($View.material as ShaderMaterial).set_shader_parameter("screenRes",
			get_viewport().size)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_viewport().size_changed.connect(viewportChanged)
	viewportChanged()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var rollAmount := 0.0
	if Input.is_action_pressed("roll_ccw"): rollAmount += 1.0
	if Input.is_action_pressed("roll_cw"): rollAmount -= 1.0
	camQuat = camQuat * Quaternion(Vector3.FORWARD, rollAmount*ROLL_SPEED*delta)
	camQuat = camQuat.normalized()

	var moveDir = Quaternion(0,0,0,0)
	if Input.is_action_pressed("move_forward"):
		moveDir += Quaternion(0,0,0,1)
	if Input.is_action_pressed("move_backward"):
		moveDir += Quaternion(0,0,0,-1)
	if Input.is_action_pressed("move_left"):
		moveDir += Quaternion(0,1,0,0)
	if Input.is_action_pressed("move_right"):
		moveDir += Quaternion(0,-1,0,0)
	if Input.is_action_pressed("move_up"):
		moveDir += Quaternion(1,0,0,0)
	if Input.is_action_pressed("move_down"):
		moveDir += Quaternion(-1,0,0,0)
	if moveDir.length_squared() > 0.1:
		moveDir = moveDir.normalized()
		pos += camQuat * moveDir * MOVE_SPEED * delta
	($View.material as ShaderMaterial).set_shader_parameter('camPos', pos);
	($View.material as ShaderMaterial).set_shader_parameter('camLook', camQuat);
	pass
