extends VBoxContainer

var ThisShape = Global.shape.new()
var nameNum = 0

signal delete(object)
signal copy(object)
signal move(object, amount)

func _ready() -> void:
	ThisShape.ID = Global.shapeID.Cube
	Global.counts[ThisShape.ID] += 1
	ThisShape.color = $Settings/ColorPickerButton.color
	$Settings/OptionButton.item_selected.emit(0)
	nameNum = Global.counts[ThisShape.ID]
	$HBoxContainer/Label.text = Global.shapeID.keys()[ThisShape.ID] + " " + str(nameNum)
	updateButtons()
	get_parent().child_order_changed.connect(updateButtons)
	get_parent().child_entered_tree.connect(updateButtons2)
	get_parent().child_exiting_tree.connect(updateButtons2)

func _process(delta: float) -> void:
	ThisShape.translate = $Settings/VectorSelect_P.OutputVector
	ThisShape.rotate = Basis.from_euler(Vector3($Settings/VectorSelect_R.OutputVector), $Settings/HBoxContainer/OptionButton2.selected)
	ThisShape.size = $Settings/VectorSelect_S.OutputVector

func save():
	var data = {
		"Type" : "MenuObject",
		"Merge_mode" : $MergeControl/VBoxContainer/OptionButton.selected,
		"Smoothing" : $MergeControl/VBoxContainer/HBoxContainer/HSlider.value,
		"Shape" : $Settings/OptionButton.selected,
		"Position" : $Settings/VectorSelect_P.strings.duplicate(),
		"Rotation" : $Settings/VectorSelect_R.strings.duplicate(),
		"Rotation_order" : $Settings/HBoxContainer/OptionButton2.selected,
		"Scale" : $Settings/VectorSelect_S.strings.duplicate(),
		"Color" : [$Settings/ColorPickerButton.color.r, $Settings/ColorPickerButton.color.g, $Settings/ColorPickerButton.color.b]
	}
	return data

func load(data):
	$MergeControl/VBoxContainer/OptionButton.selected = data["Merge_mode"]
	_on_merge_option_button_item_selected(data["Merge_mode"])
	$MergeControl/VBoxContainer/HBoxContainer/HSlider.value = data["Smoothing"]
	_on_h_slider_value_changed(data["Smoothing"])
	$Settings/OptionButton.selected = data["Shape"]
	_on_option_button_item_selected(data["Shape"])
	$Settings/VectorSelect_S.modeSwitch(data["Shape"])
	$Settings/VectorSelect_P.strings = data["Position"]
	$Settings/VectorSelect_P.loadStrings()
	$Settings/VectorSelect_R.strings = data["Rotation"]
	$Settings/VectorSelect_R.loadStrings()
	$Settings/HBoxContainer/OptionButton2.selected = data["Rotation_order"]
	$Settings/VectorSelect_S.strings = data["Scale"]
	$Settings/VectorSelect_S.loadStrings()
	$Settings/ColorPickerButton.color.r = data["Color"][0]
	$Settings/ColorPickerButton.color.g = data["Color"][1]
	$Settings/ColorPickerButton.color.b = data["Color"][2]
	_on_color_picker_button_color_changed($Settings/ColorPickerButton.color)

func updateButtons():
	updateButtons2(self)

func updateButtons2(node):
	if is_queued_for_deletion() or get_parent() == null:
		return
	if get_index() < 2:
		$HBoxContainer/VBoxContainer/Reorder_Button.disabled = true
	else:
		$HBoxContainer/VBoxContainer/Reorder_Button.disabled = false
	if get_parent().get_child_count() - 1 == get_index():
		$HBoxContainer/VBoxContainer/Reorder_Button2.disabled = true
	else:
		$HBoxContainer/VBoxContainer/Reorder_Button2.disabled = false

func _on_option_button_item_selected(index: int) -> void:
	Global.counts[ThisShape.ID] -= 1
	ThisShape.ID = index+1
	Global.counts[ThisShape.ID] += 1
	$HBoxContainer/Label.text = Global.shapeID.keys()[ThisShape.ID] + " " + str(Global.counts[ThisShape.ID])

func _on_color_picker_button_color_changed(color: Color) -> void:
	ThisShape.color = color
	$HBoxContainer/Label.self_modulate = color

func _on_edit_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		$Settings.show()
		$HBoxContainer/Edit_Button.text = "Close"
	else:
		$Settings.hide()
		$HBoxContainer/Edit_Button.text = "Edit"

func _on_delete_button_pressed() -> void:
	Global.counts[ThisShape.ID] -= 1
	delete.emit(self)

func _on_copy_button_pressed() -> void:
	copy.emit(self)
	
func _on_h_slider_value_changed(value: float) -> void:
	$MergeControl/VBoxContainer/HBoxContainer/Label2.text = str(value).pad_decimals(2)
	ThisShape.smoothing = value

func _on_merge_option_button_item_selected(index: int) -> void:
	ThisShape.merge = index

func updateName(newNum):
	$HBoxContainer/Label.text = Global.shapeID.keys()[ThisShape.ID] + " " + str(newNum)
	nameNum = newNum

func _on_reorder_up_button_pressed() -> void:
	move.emit(self, get_index()-1)

func _on_reorder_down_button_pressed() -> void:
	move.emit(self, get_index()+1)
