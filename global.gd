extends Node

enum shapeID {None=0, Cube=1, Sphere=2, Tetrahedron=3, Torus=4, Octahedron=5, Dodecahedron=6, Icosahedron=7}

class shape:
	var ID = shapeID.None
	var translate = Vector3.ZERO
	var rotate = Basis.IDENTITY
	var size = Vector3(1.0, 0.0, 0.0)
	var color = Color.DARK_GRAY
	var merge = 0
	var smoothing = 0.1

var time = 0
var timeScale = 1.0
var counts = []

var arguments = [time, PI, TAU]
var argumentNames = ["t", "pi", "tau"]

func _ready() -> void:
	counts.resize(shapeID.size())
	counts.fill(0)

func _process(delta: float) -> void:
	time += delta * timeScale
	arguments[0] = time
