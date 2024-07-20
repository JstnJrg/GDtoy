class_name Token extends RefCounted

var type : int
var value : String
var line : int
var colum : int

func _init(type_t: int, value_t: String, line_t: int, colum_t: int) -> void:
	type = type_t
	value = value_t
	line = line_t
	colum = colum_t
