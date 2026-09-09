extends Control

func _on_line_edit_text_changed(new_text: String) -> void:
	if new_text.is_valid_filename():
		$Panel/VBoxContainer/HBoxContainer/Button.disabled = false
	else:
		$Panel/VBoxContainer/HBoxContainer/Button.disabled = true

func _on_button_pressed() -> void:
	%SDFcontroller.saveScene($Panel/VBoxContainer/LineEdit.text)
	hide()
	$Panel/VBoxContainer/LineEdit.text = ""

func _on_button_2_pressed() -> void:
	hide()
	$Panel/VBoxContainer/LineEdit.text = ""
