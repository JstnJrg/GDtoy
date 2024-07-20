class_name Values extends Node

#valores ou objectos que sao validos na nossa
#linguagem 
enum value_type {
	nill,
	identifier,
	number,
	string,
	boolean,
	object,
	array,
	native_fn,
	function,
	while_v,
	if_v,
	return_v,
	break_v,
	continue_v,
	
	
	error_v
}

class RunTimeValues:
	var type : value_type = 0

class ErrorValue extends RunTimeValues:
	var msg := ''
	
	func _init(msg_t: String) -> void: 
		type = value_type.error_v
		msg = msg_t
	
	func get_error() -> String:
		return msg

class NillValue extends RunTimeValues:
	var value = null
	func _init() -> void: type = value_type.nill
 
class BooleanValue extends RunTimeValues:
	var value : bool
	func _init() -> void: type = value_type.boolean

class NumberValue extends RunTimeValues:
	var value : float
	func _init() -> void: type = value_type.number

class StringValue extends RunTimeValues:
	var value : String
	func _init() -> void: type = value_type.string

class ObjectValue extends RunTimeValues:
	var value := {}
	func _init() -> void: type = value_type.object


class ArrayValue extends RunTimeValues:
	var value : Array[RunTimeValues]
	func _init() -> void: type = value_type.array

class NativeFnValue extends  RunTimeValues:
	var call : Callable
	func _init() -> void: type = value_type.native_fn

class FunctionFnValue extends  RunTimeValues:
	var name_t: String
	var parameters: Array[String]
	var scope : EnvironmentHandler.Scope
	var body: Array[Ast.Stmt]
	func _init() -> void: type = value_type.function

class  ReturnValue extends RunTimeValues:
	var value : RunTimeValues = null
	func _init() -> void: type = value_type.return_v

class BreakValue extends  RunTimeValues:
	func _init() -> void: type = value_type.break_v

class ContinueValue extends  RunTimeValues:
	func _init() -> void: type = value_type.continue_v


class IfValue extends  RunTimeValues:
	var is_true : bool
	func _init() -> void: type = value_type.if_v

static func tp_string(id : int) -> String:
	return value_type.keys()[id]

static func mk_number (value: float) -> RunTimeValues:
	var number_v := NumberValue.new()
	number_v.value = value
	return number_v

static func mk_string (value: String) -> RunTimeValues:
	var string_v := StringValue.new()
	string_v.value = value
	return string_v

static func mk_null () -> RunTimeValues:
	return NillValue.new()

static func mk_error(msg: String) -> ErrorValue:
	return ErrorValue.new(msg)

static  func mk_default() -> RunTimeValues:
	return RunTimeValues.new()

static  func mk_boolean(bool_t: bool) -> RunTimeValues:
	var bool_ast := BooleanValue.new()
	bool_ast.value = bool_t
	return bool_ast

#static  func mk_identifier(name_: String) -> RunTimeValues:
	#var identifier := IdentifierValue.new()
	#identifier.name_ = name_
	#return identifier

static  func mk_native_function (call: Callable) -> NativeFnValue:
	var fn := NativeFnValue.new()
	fn.call = call
	return fn

static  func mk_object (properties: Dictionary) -> ObjectValue:
	var object := ObjectValue.new()
	object.value = properties
	return object


static  func mk_return(value_t: RunTimeValues) -> ContinueValue:
	return ContinueValue.new()

static  func mk_break() -> BreakValue:
	return BreakValue.new()

static  func mk_continue() -> ContinueValue:
	return ContinueValue.new()

static  func mk_if(is_true: bool) -> IfValue:
	var if_value := IfValue.new()
	if_value.is_true = is_true
	return if_value
