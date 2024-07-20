class_name RegisterHandler extends Node




static func object_register(object: Values.ObjectValue) -> void:
	
	
	var clear := func(args: Array[Values.RunTimeValues],scope: EnvironmentHandler.Scope,object: Values.ObjectValue) -> Values.RunTimeValues:
		print(3333)
		print(object.value)
		return Values.mk_null()
	
	var append := func(args: Array[Values.RunTimeValues],scope: EnvironmentHandler.Scope,object: Values.ObjectValue) -> Values.RunTimeValues:
		
		return Values.mk_null()
	
	var properties := {
		'clear': Values.mk_native_function(clear.bind(object))
		}
	
	object.value.merge(properties)
	
