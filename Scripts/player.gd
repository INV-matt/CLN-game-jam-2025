extends CharacterBody3D
class_name Player

@export var Speed: int

@export var ANIM: AnimationPlayer

@export var CAM: Camera3D
@export var HEAD: Node3D
@export var PHOTO: Node3D

var Enabled = true

var _flyingMode = false

var x_input: float
var z_input: float
var fly_input: float
var dir: Vector3

func _ready():
  # CAM.current = true
  SIGNALBUS.lock_mouse_to_camera.emit()


func _process(_delta):
  x_input = Input.get_axis("walk_left", "walk_right")
  z_input = Input.get_axis("walk_forward", "walk_backward")
  fly_input = Input.get_axis("ui_down", "ui_up")


func _physics_process(delta):
  if (!is_on_floor()) && !_flyingMode:
    velocity += get_gravity() * delta

  dir = (HEAD.transform.basis * Vector3(x_input, 0, z_input)).normalized()


  velocity.x = dir.x * Speed
  velocity.z = dir.z * Speed

  if _flyingMode:
    velocity.y = fly_input * 10
    velocity *= 5

  move_and_slide()


func _input(event: InputEvent) -> void:
  if event.is_action_pressed("ui_accept"):
    if !PHOTO.visible:
      ANIM.play("take_out_camera")
    else: ANIM.play_backwards("take_out_camera")

  if event.is_action_pressed("ui_cancel"):
    _flyingMode = !_flyingMode
