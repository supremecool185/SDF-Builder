extends HBoxContainer

var warning = false
var thisText = ""

signal NewExpression(expression)

func setText(text):
	$LineEdit.text = text
	_on_text_changed(text)

func _on_text_changed(new_text: String) -> void:
	var expression = Expression.new()
	var error = expression.parse($LineEdit.text, Global.argumentNames)
	if error != OK:
		warning = true
		return
	
	expression.execute(Global.arguments)
	if expression.has_execute_failed():
		warning = true
	else:
		warning = false
		thisText = new_text
		NewExpression.emit(expression)
	
	if warning:
		$Warning.show()
		modulate = Color.DARK_ORANGE
	else:
		$Warning.hide()
		modulate = Color.WHITE
