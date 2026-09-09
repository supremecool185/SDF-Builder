extends HFlowContainer

var OutputVector = Vector3.ZERO
var expressions = [Expression.new(), Expression.new(), Expression.new()]

@export var Default = ["0.0", "0.0", "0.0"]
var strings = ["0.0", "0.0", "0.0"]
var mode = 0

func _ready() -> void:
	$HBoxContainer/ExpressionEdit_X.setText(str(Default[0]))
	$HBoxContainer2/ExpressionEdit_Y.setText(str(Default[1]))
	$HBoxContainer3/ExpressionEdit_Z.setText(str(Default[2]))
	expressions[0].parse(str(Default[0]))
	expressions[1].parse(str(Default[1]))
	expressions[2].parse(str(Default[2]))

func loadStrings():
	$HBoxContainer/ExpressionEdit_X.setText(str(strings[0]))
	$HBoxContainer2/ExpressionEdit_Y.setText(str(strings[1]))
	$HBoxContainer3/ExpressionEdit_Z.setText(str(strings[2]))

func _process(delta: float) -> void:
	OutputVector.x = expressions[0].execute(Global.arguments)
	OutputVector.y = expressions[1].execute(Global.arguments)
	OutputVector.z = expressions[2].execute(Global.arguments)

func _on_expression_edit_x_new_expression(expression: Variant) -> void:
	expressions[0] = expression
	strings[0] = $HBoxContainer/ExpressionEdit_X.thisText

func _on_expression_edit_y_new_expression(expression: Variant) -> void:
	expressions[1] = expression
	strings[1] = $HBoxContainer2/ExpressionEdit_Y.thisText

func _on_expression_edit_z_new_expression(expression: Variant) -> void:
	expressions[2] = expression
	strings[2] = $HBoxContainer3/ExpressionEdit_Z.thisText

func modeSwitch(index):
	match index:
		0:
			$HBoxContainer.show()
			$HBoxContainer/Label.text = "X"
			$HBoxContainer2.show()
			$HBoxContainer2/Label.text = "Y"
			$HBoxContainer3.show()
			$HBoxContainer3/Label.text = "Z"
		3:
			$HBoxContainer.show()
			$HBoxContainer/Label.text = "Major"
			$HBoxContainer2.show()
			$HBoxContainer2/Label.text = "Minor"
			$HBoxContainer3.hide()
		_:
			$HBoxContainer.show()
			$HBoxContainer/Label.text = ""
			$HBoxContainer2.hide()
			$HBoxContainer3.hide()
