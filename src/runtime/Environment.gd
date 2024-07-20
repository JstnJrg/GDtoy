class_name EnvironmentHandler extends Node


static func create_global_scope() -> Scope:
	
	var global_scope := Scope.new(null)
	
	global_scope.declare_variable('null',Values.mk_null(),true)
	global_scope.declare_variable('true',Values.mk_boolean(true),true)
	global_scope.declare_variable('false',Values.mk_boolean(false),true)
	global_scope.declare_variable('PI',Values.mk_number(PI),true)
	global_scope.declare_variable('TAU',Values.mk_number(TAU),true)
	global_scope.declare_variable('e',Values.mk_number(exp(1)),true)
	NativeFunctionHandler.create_native_function_in_scope(global_scope)
	
	return global_scope



class Scope:
	
	var parent_scope : Scope = null
	var scope_variables : Dictionary
	var constants : Dictionary
	var scope_err := ErrorHandler.scope_start 
	
	func _init(parent_t) -> void:
		parent_scope = parent_t
	
	func declare_variable(var_name: String, value: Values.RunTimeValues, is_constant : bool) -> Values.RunTimeValues:
		
		if scope_variables.has(var_name):
			return Values.mk_error(scope_err+'cannot declare \"%s\" variable as it already is defined'%var_name)
		
		elif parent_scope and parent_scope.scope_variables.has(var_name):
			return Values.mk_error(scope_err+'cannot declare \"%s\" variable as it already is defined'%var_name)

		
		scope_variables[var_name] = value
		
		if is_constant:
			constants[var_name] = value
		
		return value
	
	func assign_var (var_name: String, value: Values.RunTimeValues) -> Values.RunTimeValues:
		
		# se esta definido no scopo
		var scope := check_var_in_scope(var_name)
		
		if not scope:
			return Values.mk_error(scope_err+'cannot resolve \"%s\" as it does not defined'%var_name)
		
		if scope.constants.has(var_name):
			return Values.mk_error(scope_err+'cannot reasign to variable \"%s\" as it was declared constant'%var_name)
		
		scope.scope_variables[var_name] = value
		
		return value
	
	func check_var_in_scope (var_name: String) -> Scope:
		
		if scope_variables.has(var_name):
			return self
		
		elif not parent_scope: return
		
		return parent_scope.check_var_in_scope(var_name)
	
	func lookup_var (var_name: String) -> Values.RunTimeValues:
		var env := check_var_in_scope(var_name)
		return env.scope_variables[var_name] if env else Values.mk_error(scope_err+'cannot resolve \"%s\" as it does not defined'%var_name)
	
	func free_parent() -> void:
		if parent_scope: parent_scope = null
	
	func free_scope() -> void:
		scope_variables.clear()
		constants.clear()
		if parent_scope: parent_scope = null
