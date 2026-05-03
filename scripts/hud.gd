extends CanvasLayer

signal switch_pressed

@onready var _blocks_label: Label = $Blocks

func set_blocks(count: int) -> void:
	if _blocks_label:
		_blocks_label.text = "Blocks: %d" % count

func _on_left_button_down() -> void:  Input.action_press("ui_left")
func _on_left_button_up() -> void:    Input.action_release("ui_left")
func _on_right_button_down() -> void: Input.action_press("ui_right")
func _on_right_button_up() -> void:   Input.action_release("ui_right")
func _on_gas_button_down() -> void:   Input.action_press("ui_up")
func _on_gas_button_up() -> void:     Input.action_release("ui_up")
func _on_brake_button_down() -> void: Input.action_press("ui_down")
func _on_brake_button_up() -> void:   Input.action_release("ui_down")
func _on_switch_pressed() -> void:    switch_pressed.emit()
