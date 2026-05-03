extends VehicleBody3D

@export var max_steer: float = 0.45
@export var steer_speed: float = 2.5
@export var engine_power: float = 800.0
@export var reverse_power: float = 350.0
@export var brake_force: float = 6.0
@export var idle_brake: float = 0.5
@export var upright_torque: float = 0.0
@export var upright_damping: float = 0.0

func _physics_process(delta: float) -> void:
	var steer_target := Input.get_axis("ui_right", "ui_left") * max_steer
	steering = move_toward(steering, steer_target, steer_speed * delta)

	var fwd := Input.is_action_pressed("ui_up")
	var rev := Input.is_action_pressed("ui_down")
	var forward_speed := -global_transform.basis.z.dot(linear_velocity)

	if fwd:
		engine_force = -engine_power
		brake = 0.0
	elif rev:
		if forward_speed > 1.0:
			engine_force = 0.0
			brake = brake_force
		else:
			engine_force = reverse_power
			brake = 0.0
	else:
		engine_force = 0.0
		brake = idle_brake

	if upright_torque > 0.0:
		var lean_axis := global_transform.basis.y.cross(Vector3.UP)
		apply_torque(lean_axis * upright_torque)
		if upright_damping > 0.0:
			var roll_axis := global_transform.basis.z
			var roll_rate := angular_velocity.dot(roll_axis)
			apply_torque(-roll_axis * roll_rate * upright_damping)
