extends Camera3D

@export var target_path: NodePath
@export var distance: float = 7.0
@export var height: float = 3.5
@export var look_height: float = 1.0
@export var smoothness: float = 6.0

var _target: Node3D

func _ready() -> void:
	if target_path != NodePath(""):
		_target = get_node_or_null(target_path)

func set_target(t: Node3D) -> void:
	_target = t

func _physics_process(delta: float) -> void:
	if _target == null:
		return
	var basis := _target.global_transform.basis
	var desired := _target.global_position + basis.z * distance + Vector3.UP * height
	global_position = global_position.lerp(desired, clamp(smoothness * delta, 0.0, 1.0))
	look_at(_target.global_position + Vector3.UP * look_height, Vector3.UP)
