extends Sprite3D

var shapeNodes = []
var shapes = []

var menuObject = preload("res://MenuObject.tscn")

enum {Preset=0, User=1}

func _ready() -> void:
	var dir = DirAccess.open("user://")
	dir.make_dir("User Scenes")
	
	updateSaveList(Preset)
	updateSaveList(User)

func _on_button_pressed() -> void:
	addObject()

func addObject():
	var inst = menuObject.instantiate()
	$"../UI/TabContainer/Scene/Padding/SceneList".add_child(inst)
	shapeNodes.append(inst)
	shapes.append(inst.ThisShape)
	if shapes.size() == 32:
		$"../UI/TabContainer/Scene/Padding/SceneList/Button".disabled = true
	if inst == shapeNodes[0]:
		inst.get_node("MergeControl").hide()
	
	inst.delete.connect(DeleteShape)
	inst.copy.connect(CopyShape)
	inst.move.connect(MoveShape)
	
	return inst

func _process(delta: float) -> void:
	var IDs = material_override.get_shader_parameter("shapeTypes") as Array
	var transforms = material_override.get_shader_parameter("shapeTransforms") as Array
	var rotations = material_override.get_shader_parameter("shapeRotations") as Array
	var scales = material_override.get_shader_parameter("shapeScales") as Array
	var colors = material_override.get_shader_parameter("shapeColors") as Array
	var merges = material_override.get_shader_parameter("shapeMerge") as Array
	var smooths = material_override.get_shader_parameter("shapeSmooth") as Array
	
	for i in shapes.size():
		IDs[i] = shapes[i].ID
		transforms[i] = shapes[i].translate
		rotations[i] = shapes[i].rotate
		scales[i] = shapes[i].size
		colors[i] = shapes[i].color
		merges[i] = shapes[i].merge
		smooths[i] = shapes[i].smoothing
	
	material_override.set_shader_parameter("shapeTypes", IDs)
	material_override.set_shader_parameter("shapeRotations", rotations)
	material_override.set_shader_parameter("shapeTransforms", transforms)
	material_override.set_shader_parameter("shapeScales", scales)
	material_override.set_shader_parameter("shapeColors", colors)
	material_override.set_shader_parameter("shapeMerge", merges)
	material_override.set_shader_parameter("shapeSmooth", smooths)
	
	material_override.set_shader_parameter("cameraPos", $"../UI/TabContainer/Settings/VBoxContainer/CameraPosition".OutputVector)
	material_override.set_shader_parameter("cameraRot", Basis.from_euler(Vector3($"../UI/TabContainer/Settings/VBoxContainer/CameraRotation".OutputVector), $"../UI/TabContainer/Settings/VBoxContainer/HBoxContainer4/RotationOrder".selected))
	material_override.set_shader_parameter("lightPos", $"../UI/TabContainer/Settings/VBoxContainer/LightPosition".OutputVector)

func DeleteShape(object):
	shapes.erase(object.ThisShape)
	shapeNodes.erase(object)
	
	object.queue_free()
	
	for i in shapeNodes:
		if i.ThisShape.ID == object.ThisShape.ID:
			if object.nameNum < i.nameNum:
				i.updateName(i.nameNum - 1)
	
	var arr = []
	arr.resize(32)
	material_override.set_shader_parameter("shapeTypes", arr)
	
	if shapeNodes.size() > 0:
		shapeNodes[0].get_node("MergeControl").hide()
	
	$"../UI/TabContainer/Scene/Padding/SceneList/Button".disabled = false

func CopyShape(object):
	var data = object.save()
	var inst = addObject()
	inst.load(data)

func MoveShape(object, newIndex):
	var oldIndex = object.get_index()
	$"../UI/TabContainer/Scene/Padding/SceneList".move_child(object, newIndex)
	
	if newIndex == 1:
		object.get_node("MergeControl").hide()
		shapeNodes[newIndex-1].get_node("MergeControl").show()
	
	if oldIndex == 1:
		object.get_node("MergeControl").show()
		shapeNodes[newIndex-1].get_node("MergeControl").hide()
	
	var swap = shapes[newIndex-1]
	shapes[newIndex-1] = shapes[oldIndex-1]
	shapes[oldIndex-1] = swap
	
	swap = shapeNodes[newIndex-1]
	shapeNodes[newIndex-1] = shapeNodes[oldIndex-1]
	shapeNodes[oldIndex-1] = swap

func _on_h_slider_value_changed(value: float) -> void:
	Global.timeScale = pow(2, value)
	$"../UI/TabContainer/Settings/VBoxContainer/Smoothing/Label".text = str(Global.timeScale).pad_decimals(2)

func saveScene(fileName):
	var saveFile = FileAccess.open("user://User Scenes/"+fileName+".scene", FileAccess.WRITE)
	var settingsData = {
		"Type" : "Settings",
		"Camera_position" : $"../UI/TabContainer/Settings/VBoxContainer/CameraPosition".strings.duplicate(),
		"Camera_rotation" : $"../UI/TabContainer/Settings/VBoxContainer/CameraRotation".strings.duplicate(),
		"Camera_rotate_order" : $"../UI/TabContainer/Settings/VBoxContainer/HBoxContainer4/RotationOrder".selected,
		"Light_position" : $"../UI/TabContainer/Settings/VBoxContainer/LightPosition".strings.duplicate(),
		"Time_scale" : $"../UI/TabContainer/Settings/VBoxContainer/Smoothing/HSlider".value
	}
	saveFile.store_line( JSON.stringify(settingsData) )
	
	for object in shapeNodes:
		var json = JSON.stringify( object.save() )
		saveFile.store_line(json)
	
	updateSaveList(User)

func updateSaveList(mode):
	var container
	var dir
	var path
	
	match mode:
		User:
			container = $"../UI/TabContainer/Save & Load/VBoxContainer/ScrollContainer/VBoxContainer/User"
			path = "user://User Scenes/"
			dir = DirAccess.open(path)
		Preset:
			container = $"../UI/TabContainer/Save & Load/VBoxContainer/ScrollContainer/VBoxContainer/Presets"
			path = "res://Preset Scenes/"
			dir = DirAccess.open(path)
	
	var buttons = container.get_children()
	for i in buttons:
		i.queue_free()
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var newButton = Button.new()
		newButton.text = file_name.replace(".scene", "")
		newButton.pressed.connect(loadScene.bind(path + file_name))
		container.add_child(newButton)
		file_name = dir.get_next()

func loadScene(path):
	shapes.clear()
	shapeNodes.clear()
	Global.counts.fill(0)
	var arr = []
	arr.resize(32)
	material_override.set_shader_parameter("shapeTypes", arr)
	
	if !FileAccess.file_exists(path):
		return
	
	var objects = $"../UI/TabContainer/Scene/Padding/SceneList".get_children()
	for i in objects:
		if i != $"../UI/TabContainer/Scene/Padding/SceneList/Button":
			i.queue_free()
	
	var saveFile = FileAccess.open(path, FileAccess.READ)
	
	while saveFile.get_position() < saveFile.get_length():
		var jsonLine = saveFile.get_line()
		
		var json = JSON.new()
		var result = json.parse(jsonLine)
		if not result == OK:
			continue
		var data = json.data
		
		if data["Type"] == "Settings":
			$"../UI/TabContainer/Settings/VBoxContainer/CameraPosition".strings = data["Camera_position"]
			$"../UI/TabContainer/Settings/VBoxContainer/CameraPosition".loadStrings()
			$"../UI/TabContainer/Settings/VBoxContainer/CameraRotation".strings = data["Camera_rotation"]
			$"../UI/TabContainer/Settings/VBoxContainer/CameraRotation".loadStrings()
			$"../UI/TabContainer/Settings/VBoxContainer/LightPosition".strings = data["Light_position"]
			$"../UI/TabContainer/Settings/VBoxContainer/LightPosition".loadStrings()
			$"../UI/TabContainer/Settings/VBoxContainer/HBoxContainer4/RotationOrder".selected = data["Camera_rotate_order"]
			$"../UI/TabContainer/Settings/VBoxContainer/Smoothing/HSlider".value = data["Time_scale"]
			_on_h_slider_value_changed(data["Time_scale"])
		elif data["Type"] == "MenuObject":
			var inst = addObject()
			inst.load(data)

func _on_save_button_pressed() -> void:
	$"../UI/SavePopup".show()

func _on_button_3_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path("user://User Scenes/"))
