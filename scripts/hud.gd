extends CanvasLayer

signal switch_pressed

func _on_left_button_down() -> void:  Input.action_press("ui_left")
func _on_left_button_up() -> void:    Input.action_release("ui_left")
func _on_right_button_down() -> void: Input.action_press("ui_right")
func _on_right_button_up() -> void:   Input.action_release("ui_right")
func _on_gas_button_down() -> void:   Input.action_press("ui_up")
func _on_gas_button_up() -> void:     Input.action_release("ui_up")
func _on_brake_button_down() -> void: Input.action_press("ui_down")
func _on_brake_button_up() -> void:   Input.action_release("ui_down")
func _on_switch_pressed() -> void:    switch_pressed.emit()
