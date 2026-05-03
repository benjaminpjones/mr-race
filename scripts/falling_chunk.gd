extends RigidBody3D

@export var despawn_y: float = -10.0

func _physics_process(_delta: float) -> void:
	if global_position.y < despawn_y:
		queue_free()
