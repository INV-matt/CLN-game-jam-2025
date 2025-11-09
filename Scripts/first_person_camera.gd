extends Node3D


@export var MouseSensitivity: float = .01
@export var Camera: Camera3D

var Enabled = true


func _ready():
  SIGNALBUS.free_mouse_from_camera.connect(_on_free_mouse)
  SIGNALBUS.lock_mouse_to_camera.connect(_on_lock_mouse)

func _unhandled_input(event: InputEvent) -> void:
  if Enabled && event is InputEventMouseMotion:
    rotate_y(-event.relative.x * MouseSensitivity)
    Camera.rotate_x(-event.relative.y * MouseSensitivity)
    Camera.rotation.x = clamp(Camera.rotation.x, deg_to_rad(-45), deg_to_rad(60))


func _on_free_mouse():
  Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_lock_mouse():
  Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
