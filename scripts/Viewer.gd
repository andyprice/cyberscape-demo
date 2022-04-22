extends KinematicBody

onready var cam = $GimbalHorizontal/GimbalVertical/Camera
onready var vgimbal = $GimbalHorizontal/GimbalVertical
onready var hgimbal = $GimbalHorizontal

onready var init_transform = transform
onready var init_hgimbal_transform = hgimbal.transform
onready var init_vgimbal_transform = vgimbal.transform

const SPEED = 5.0

signal viewer_moved(player)

func _physics_process(_delta):
	if Input.is_action_pressed("quit"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().quit()

	var vel = global_transform.basis.x * SPEED
	var _coll = move_and_slide(vel)

var last_pos = Vector3.ZERO
func _process(_delta):
	var pos = global_transform.origin
	if last_pos != pos:
		pos = last_pos
		emit_signal("viewer_moved", self)
