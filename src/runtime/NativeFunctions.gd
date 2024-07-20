class_name  NativeFunctionHandler extends Node


static func create_native_function_in_scope(scope: EnvironmentHandler.Scope) -> void:

	scope.declare_variable('print', Values.mk_native_function(_print),true)
	
	scope.declare_variable('time',Values.mk_object(
		{
			'time_sec':Values.mk_native_function(_time_sec)
		}
		),
		true
		)
	
	scope.declare_variable('system',Values.mk_object(
		{
			'get_fps':Values.mk_native_function(get_fps)
		}
		),
		true
		)
	
	scope.declare_variable('math',Values.mk_object(
		{
			'e': Values.mk_number(exp(1)),
			'sin': Values.mk_native_function(_sen),
			'cos': Values.mk_native_function(_cos),
			'posmod': Values.mk_native_function(_posmod),
			'sqrt': Values.mk_native_function(_sqrt),
			'randi': Values.mk_native_function(_randi),
			'randomize': Values.mk_native_function(_randomize),
			'rand_range': Values.mk_native_function(_rand_range),
			}
		),
		true
		)

# time
static func _time_sec(args: Array[Values.RunTimeValues], _scope: EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	var size := args.size()
	if size : return Values.mk_error(ErrorHandler.interpreter_start+'time_msec function expects no argument, but was called with %s'%size)
	return Values.mk_number(Time.get_ticks_msec()*0.001)

#Performance
static func get_fps(args: Array[Values.RunTimeValues], _scope: EnvironmentHandler.Scope) -> Values.RunTimeValues:
	var size := args.size()
	if size : return Values.mk_error(ErrorHandler.interpreter_start+'time_msec function expects no argument, but was called with %s'%size)
	return Values.mk_number(Engine.get_frames_per_second())

static func _print(args: Array[Values.RunTimeValues], _scope: EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	for arg in args:
		
		match arg.type:
			Values.value_type.number:
				print(arg.value)
			Values.value_type.boolean:
				print(arg.value)
			Values.value_type.nill:
				print(arg.value)
			Values.value_type.array:
				args.append_array(arg.value)
			Values.value_type.string:
				print(arg.value)
			Values.value_type.error_v:
				printerr(arg.msg)
				return arg
			_:
				pass
	
	return Values.mk_null()

#Math
static func _posmod(args: Array[Values.RunTimeValues], scope: EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	var size := args.size()
	
	if size != 2:
		return Values.mk_error(ErrorHandler.interpreter_start+'posmod function expects two arguments, but was called with %s'%size)
	
	elif args[0].type != Values.value_type.number or args[1].type != Values.value_type.number:
		return Values.mk_error(ErrorHandler.interpreter_start+'posmod function only expects number as argument')

	return Values.mk_number(posmod(args[0].value,args[1].value))

static func _sen(args: Array[Values.RunTimeValues], scope: EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	var size := args.size()
	
	if size != 1:
		return Values.mk_error(ErrorHandler.interpreter_start+'sin function expects one argument, but was called with %s'%size)
	
	elif args[0].type != Values.value_type.number:
		return Values.mk_error(ErrorHandler.interpreter_start+'sin function only expects number as argument')

	return Values.mk_number(sin(args[0].value))

static func _cos(args: Array[Values.RunTimeValues], scope: EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	var size := args.size()
	
	if size != 1:
		return Values.mk_error(ErrorHandler.interpreter_start+'cos function expects one argument, but was called with %s'%size)
	
	elif args[0].type != Values.value_type.number:
		return Values.mk_error(ErrorHandler.interpreter_start+'cos function only expects number as argument')

	return Values.mk_number(cos(args[0].value))

static func _sqrt(args: Array[Values.RunTimeValues], scope: EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	var size := args.size()
	
	if size != 1:
		return Values.mk_error(ErrorHandler.interpreter_start+'sqrt function expects one argument, but was called with %s'%size)
	
	elif args[0].type != Values.value_type.number:
		return Values.mk_error(ErrorHandler.interpreter_start+'sqrt function only expects number as argument')

	return Values.mk_number(sqrt(args[0].value))

static func _randi(args: Array[Values.RunTimeValues], scope: EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	var size := args.size()
	
	if size != 0: return Values.mk_error(ErrorHandler.interpreter_start+'randi function expects none argument, but was called with %s'%size)
	return Values.mk_number(randi())

static func _rand_range(args: Array[Values.RunTimeValues], scope: EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	var size := args.size()
	
	if size != 2:
		return Values.mk_error(ErrorHandler.interpreter_start+'rand_range function expects none argument, but was called with %s'%size)
	
	elif args[0].type != Values.value_type.number or args[1].type != Values.value_type.number:
		return Values.mk_error(ErrorHandler.interpreter_start+'rand_range function only expects number as argument')
	
	return Values.mk_number(randf_range(args[0].value,args[1].value))

static func _randomize(args: Array[Values.RunTimeValues], scope: EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	var size := args.size()
	
	if size != 0:
		return Values.mk_error(ErrorHandler.interpreter_start+'randomize function expects none argument, but was called with %s'%size)
	
	randomize()
	
	return Values.mk_null()
