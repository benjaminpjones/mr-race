extends Node3D

@export var vehicle_scenes: Array[PackedScene] = []
@export var spawn_height: float = 1.5
@export var respawn_y_threshold: float = -15.0

var _current: VehicleBody3D
var _index: int = 0

@onready var _camera: Camera3D = $ChaseCamera
@onready var _hud: CanvasLayer = $HUD
@onready var _floor: Node = get_node_or_null("Track/FallingFloor")

func _ready() -> void:
	if _hud.has_signal("switch_pressed"):
		_hud.switch_pressed.connect(switch_vehicle)
	if _floor and _floor.has_signal("blocks_removed_changed") and _hud.has_method("set_blocks"):
		_floor.blocks_removed_changed.connect(_hud.set_blocks)
	_spawn_at_origin()

func _physics_process(_delta: float) -> void:
	if _current and _current.global_position.y < respawn_y_threshold:
		_spawn_at_origin()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_V or event.keycode == KEY_SPACE:
			switch_vehicle()
		elif event.keycode == KEY_R:
			if _floor and _floor.has_method("reset"):
				_floor.reset()
			_spawn_at_origin()

func switch_vehicle() -> void:
	if vehicle_scenes.is_empty():
		return
	_index = (_index + 1) % vehicle_scenes.size()
	var pos := Vector3(0, spawn_height, 0)
	var rot := Basis()
	if _current:
		pos = _current.global_position
		pos.y = spawn_height
		rot = _current.global_transform.basis
		_current.queue_free()
		_current = null
	_spawn_current(pos, rot)

func _spawn_at_origin() -> void:
	if _current:
		_current.queue_free()
		_current = null
	_spawn_current(Vector3(0, spawn_height, 0), Basis())

func _spawn_current(pos: Vector3, rot: Basis) -> void:
	var v := vehicle_scenes[_index].instantiate() as VehicleBody3D
	add_child(v)
	v.global_transform = Transform3D(rot, pos)
	_current = v
	if _camera and _camera.has_method("set_target"):
		_camera.set_target(v)
	if _floor and _floor.has_method("set_vehicle"):
		_floor.set_vehicle(v)
