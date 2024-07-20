class_name Interpreter extends Node

#classe que interpreta os dados da AST, e transforma-os  
# em valores que sao permitidos na lignuagem
var interpreter_err := ErrorHandler.interpreter_start


func evalue (ast_node: Ast.Stmt, scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	match ast_node.type:
		
		Ast.node_type.NumericLiteral:
			var value := Values.NumberValue.new()
			value.value = ast_node.value
			value.type = Values.value_type.number
			return value
		
		Ast.node_type.StringLiteral:
			return evalue_string_expression(ast_node,scope)
		
		Ast.node_type.Identifier:
			return evalue_identifier(ast_node,scope)
		
		Ast.node_type.VarDeclarationStmt:
			return evalue_var_declaration(ast_node,scope)
		
		
		Ast.node_type.BinaryExpr:
			return evalue_binary_expr(ast_node,scope)
		
		Ast.node_type.Program:
			return evalue_program(ast_node,scope)
		
		Ast.node_type.AssignmentExpr:
			return evalue_assignment_expression(ast_node,scope)
		
		Ast.node_type.ObjectLiteral:
			return evalue_object_expression(ast_node,scope)
		
		Ast.node_type.ArrayLiteral:
			return evalue_array_expression(ast_node,scope)
		
		Ast.node_type.EqualityExpr:
			return evalue_equality_expression(ast_node,scope)
		
		Ast.node_type.EqualityAssignExpr:
			return evalue_equality_assign_expression(ast_node,scope)
		
		Ast.node_type.MemberExpr:
			return evalue_member_expression(ast_node,scope)
		
		Ast.node_type.CallExpr:
			return evalue_call_expression(ast_node,scope)
		
		Ast.node_type.FunctionDeclaration:
			return evalue_function_declaration(ast_node,scope)
		
		Ast.node_type.WhileExpr:
			return evalue_while_expression(ast_node,scope)
		
		Ast.node_type.IfExpr:
			return evalue_if_expression(ast_node,scope)
		
		Ast.node_type.ReturnExpr:
			return evalue_return_expression(ast_node,scope)
		
		Ast.node_type.BreakExpr:
			return evalue_break_expression(ast_node,scope)
		
		Ast.node_type.ContinueExpr:
			return evalue_continue_expression(ast_node,scope)
		
		
		Ast.node_type.ErrorLiteral:
			return evalue_error_expression(ast_node)
		
		_:
			assert(false,'[interpreter] --> for %s, method not implemeted yet'%Ast.node_string(ast_node.type))
			return 
	

##==================== PROGRAMA ===========

# a interpretacao do programa comeca aqui
func evalue_program(program: Ast.Program, scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	
	for stmt in program.body:
		var value := evalue(stmt,scope)
		
		if value.type == Values.value_type.error_v: 
			scope.free_scope()
			program.free_data()
			printerr(value.msg)
			return value
	
	#
	scope.free_scope()
	program.free_data()
	
	return Values.mk_null()

# lida com possiveis erros que podem ocorrer ao longo 
# da interpretacao, permite sair da recusao com seguranca
func evalue_error_expression(ast_node: Ast.ErrorExpr) -> Values.RunTimeValues:
	return Values.mk_error(ast_node.get_error())


####===================== EXPRESSOES ===========================

#avalia as variaveis
func evalue_var_declaration(ast_node: Ast.VarDeclaration, scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	var value := evalue(ast_node.value,scope) if ast_node.value else Values.mk_null()
	
	if value.type == Values.value_type.error_v:  return value
	
	elif value.type == Values.value_type.function or value.type == Values.value_type.native_fn:
		return Values.mk_error(interpreter_err+'cannot assign \"%s\", with function reference'%ast_node.identifier)
	
	return scope.declare_variable(ast_node.identifier,value,ast_node.constant)

func evalue_identifier (ast_node: Ast.Identifier, scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	return  scope.lookup_var(ast_node.symbol)

func evalue_assignment_expression(ast_node: Ast.AssignmentExpr, scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	if ast_node.assigne.type != Ast.node_type.Identifier:
		return Values.mk_error(interpreter_err+'invalid %s, the value must be a valid expression'%Ast.node_string(ast_node.type))
	
	var identifier := ast_node.assigne
	var value := evalue(ast_node.value,scope)
	
	if value.type == Values.value_type.error_v:  return value
	
	#nao é permitido a variavel ser assinado com falor de uma funcao
	# ou uma funcao nativa
	elif value.type == Values.value_type.function or value.type == Values.value_type.native_fn:
		return Values.mk_error(interpreter_err+'cannot assign \"%s\", with function reference'%identifier.symbol)
	
	return scope.assign_var(identifier.symbol,value)


#string
func evalue_string_expression(ast_node: Ast.StringLiteral, scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	return Values.mk_string(ast_node.value)

func evalue_equality_expression(ast_node: Ast.EqualityExpr, scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	var left := evalue(ast_node.letf,scope)
	var right := evalue(ast_node.right,scope)
	
	if left.type == Values.value_type.error_v:  return left
	elif right.type == Values.value_type.error_v:  return right
	
	return evalue_equality_operators(left,right,ast_node.operator)

func evalue_equality_operators (lhs: Values.RunTimeValues, rhs: Values.RunTimeValues, operator: String) -> Values.RunTimeValues:
	
	var logicians := ['and','or']
	
	if logicians.has(operator):
		match  operator:
			'and': return Values.mk_boolean(lhs.value and rhs.value)
			'or':  return Values.mk_boolean(lhs.value or rhs.value)
	
	elif lhs.type == rhs.type:
		
		#NUMBER AND STRING
		if lhs.type == Values.value_type.number or lhs.type == Values.value_type.string:
			match operator:
				'==': return Values.mk_boolean(lhs.value == rhs.value)
				'<=': return Values.mk_boolean(lhs.value <= rhs.value)
				'>=': return Values.mk_boolean(lhs.value >= rhs.value)
				'>':  return Values.mk_boolean(lhs.value > rhs.value)
				'<':  return Values.mk_boolean(lhs.value < rhs.value)
				'!=': return Values.mk_boolean(lhs.value != rhs.value)
				'and': return Values.mk_boolean(lhs.value and rhs.value)
		
		#ARRAY
		elif lhs.type == Values.value_type.array:
			match operator:
				'<=': return Values.mk_boolean(lhs.elements <= rhs.elements)
				'>=': return Values.mk_boolean(lhs.elements >= rhs.elements)
				'>':  return Values.mk_boolean(lhs.elements > rhs.elements)
				'<':  return Values.mk_boolean(lhs.elements < rhs.elements)		
		
		#BOOL
		elif lhs.type == Values.value_type.boolean:
			match operator:
				'==': return Values.mk_boolean(lhs.value == rhs.value)
		
		else : 
			print(Values.tp_string(lhs.type))
	
	
	#tipos diferentes retorna falso
	return Values.mk_boolean(false)



func evalue_equality_assign_expression(ast_node: Ast.EqualityAssignExpr, scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	if ast_node.left.type != Ast.node_type.Identifier :
		return Values.mk_error(interpreter_err+'invalid %s, assigne must be a identifier'%Ast.node_string(ast_node.type))
	
	var value := evalue(ast_node.right,scope)
	if value.type == Values.value_type.error_v:  return value
	
	var var_value := scope.lookup_var(ast_node.left.symbol)
	
	if var_value.type != Values.value_type.number or value.type != Values.value_type.number: 
		return Values.mk_error(interpreter_err+'invalid peration,\"%s\" just allow contable value'%[ast_node.operator])
	
	
	var new_value := get_equality_assign_expr(var_value,value,ast_node.operator)
	
	return scope.assign_var(ast_node.left.symbol,new_value)

func get_equality_assign_expr (var_value: Values.RunTimeValues,value: Values.RunTimeValues, operator: String) -> Values.RunTimeValues:
	
	match  operator:
		'-=': return evalue_numeric_binary_exp(var_value,value,'-')
		'+=': return evalue_numeric_binary_exp(var_value,value,'+')
		'*=': return evalue_numeric_binary_exp(var_value,value,'*')
		'/=': return evalue_numeric_binary_exp(var_value,value,'/')
		_ : 
			return Values.mk_error(interpreter_err+'invalid %s operation'%operator)
	
	return Values.mk_null()



func evalue_object_expression(ast_node: Ast.ObjectLiteral, scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	var object := Values.ObjectValue.new()
	var properties := ast_node.properties
	
	for property: Ast.Property in properties:
		
		var key := property.key
		var value := property.value
		
		#verifica se a chave é uma variavel ja
		#declarada e busca seu valor se nao for fornecido
		#uma chave {a,b:5}
		
		var var_value := scope.lookup_var(key) if not value else evalue(value,scope)
		if var_value.type == Values.value_type.error_v:  return var_value
		
		object.value[key] = var_value
	
	return object

func evalue_array_expression(ast_node: Ast.ArrayLiteral, scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	var array_value := Values.ArrayValue.new()
	var properties := ast_node.properties
	
	for element in properties :
		var value := evalue(element,scope)
		if value.type == Values.value_type.error_v:  
			ast_node.properties.clear()
			return value
		array_value.value.append(value)
	
	#limpa os dados
	properties.clear()
	
	return array_value


#Avaliador de expressoes
func evalue_binary_expr( bin_op: Ast.BinaryExpr, scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	var lhs := evalue(bin_op.left,scope)
	var rhs := evalue(bin_op.right,scope)
	
	if lhs.type == Values.value_type.error_v:  return lhs
	elif rhs.type == Values.value_type.error_v:  return rhs
	
	
	#se ambos forem numeros
	if lhs.type == rhs.type:
		match rhs.type:
			Values.value_type.number: return evalue_numeric_binary_exp(lhs,rhs,bin_op.operator)
			Values.value_type.string: return evalue_string_binary_exp(lhs,rhs,bin_op.operator)
			_: return Values.mk_error(interpreter_err+'\"%s\"cannot evaluate with \"%s"\"'%[bin_op.operator,Values.tp_string(lhs.type)])
	
	else :  return Values.mk_error(interpreter_err+'\"%s\"cannot evalue with different type'%[bin_op.operator])
	
	#se na forem numeros, retorna nulo
	return Values.mk_null()

func evalue_numeric_binary_exp(lhs:Values.NumberValue,rhs: Values.NumberValue, operator: String) -> Values.RunTimeValues:
	match operator:
		'+': return Values.mk_number(lhs.value+rhs.value)
		'-': return Values.mk_number(lhs.value-rhs.value)
		'*': return Values.mk_number(lhs.value*rhs.value)
		'/': 
			if rhs.value == 0.0: return Values.mk_error(interpreter_err+'\"%s\" by zero, invalid  operation.  '%operator)
			return Values.mk_number(lhs.value/rhs.value)
		'%': 
			if rhs.value == 0.0: return Values.mk_error(interpreter_err+'\"%s\" by zero, invalid  operation.  '%operator)
			return Values.mk_number(int(lhs.value)%int(rhs.value))
	
	return Values.mk_error(interpreter_err+'\"%s\"invalid operation'%operator)

func evalue_string_binary_exp(lhs:Values.StringValue,rhs: Values.StringValue, operator: String) -> Values.RunTimeValues:
	match operator:
		'+': return Values.mk_string(lhs.value+rhs.value)
		_:
			return Values.mk_error(interpreter_err+'invalid \"%s\" operator with string.'%operator)
	
	return Values.mk_error(interpreter_err+'\"%s\"invalid operation'%operator)


# lidam com expressoes mais complexas
func evalue_member_expression(ast_node: Ast.MemberExpr, scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	var object := evalue(ast_node.object,scope)
	if object.type == Values.value_type.error_v: return object

	var property_key : String = ast_node.property.symbol
	
	
	if object.type != Values.value_type.object:
		return Values.mk_error(interpreter_err+'member acess is only allowed for object type')
	
	elif not object.value.has(property_key):
		return Values.mk_error(interpreter_err+'invalid acess to property or key \"%s\" on base of type object'%property_key)
	
	return object.value[property_key]

func evalue_call_expression(ast_node: Ast.CallExpr, scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	#chama o membro, ou seja, o member expression
	var args = ast_node.args.map(evalue.bind(scope))
	
	#membro expression
	var caller := evalue(ast_node.caller,scope)
	
	
	
	if caller.type == Values.value_type.error_v: return caller
	
	elif caller.type == Values.value_type.native_fn:
		var args_t : Array[Values.RunTimeValues] = []
		args_t.assign(args)
		return caller.call.call(args_t,scope)
	
	elif caller.type == Values.value_type.function:
		
		#caller = caller as Values.FunctionFnValue
		var fn_scope := EnvironmentHandler.Scope.new(caller.scope)
		
		if caller.parameters.size() != args.size():
			return Values.mk_error(interpreter_err+'function expects %s arguments, but was called with %s'%[caller.parameters.size(),args.size()])
		
		for indx in caller.parameters.size(): fn_scope.declare_variable(caller.parameters[indx],args[indx],false)
		
		for s in caller.body:
			
			var value := evalue(s,fn_scope)
			
			if value.type == Values.value_type.error_v: return value
			elif value.type == Values.value_type.return_v: return value.value
	
	else : return Values.mk_error(interpreter_err+'invalid function call.')
	
	return Values.mk_null()

func evalue_function_declaration(ast_node: Ast.FunctionDeclaration, scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	var fn_value := Values.FunctionFnValue.new()
	fn_value.name_t = ast_node.name_t
	fn_value.parameters = ast_node.parameters
	fn_value.body = ast_node.body
	fn_value.scope = scope
	
	return scope.declare_variable(fn_value.name_t,fn_value,true)


### LOOPS, responsavel por lidar com lacos e sua estruturas
func evalue_return_expression(ast_node: Ast.ReturnExpr, _scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	var return_value := Values.ReturnValue.new()
	return_value.value = evalue(ast_node.retun,_scope) if ast_node.retun else Values.mk_null()
	return return_value

func evalue_break_expression(_ast_node: Ast.BreakExpr, _scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	return Values.mk_break()

func evalue_continue_expression(_ast_node: Ast.ContinueExpr, _scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	return Values.mk_continue()

func evalue_while_expression(ast_node: Ast.WhileExpr, scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	var body := ast_node.body
	var value_g := evalue(ast_node.condition,scope)
	if value_g.type == Values.value_type.error_v: return value_g
	
	while value_g.value :
		
		var private_scope := EnvironmentHandler.Scope.new(scope)
		var can_break := false
		
		for s in body:
			 
			var value := evalue(s,private_scope)
			
			if value.type == Values.value_type.error_v: return value
			elif value.type == Values.value_type.return_v: return value
			elif value.type == Values.value_type.continue_v: break
			
			elif value.type == Values.value_type.break_v:
				can_break = true
				break
			
			
		
		value_g = evalue(ast_node.condition,scope)
		
		if can_break: break

	
	return Values.mk_null()

func evalue_if_expression(ast_node: Ast.IfExpr, scope : EnvironmentHandler.Scope) -> Values.RunTimeValues:
	
	var private_scope := EnvironmentHandler.Scope.new(scope)
	var value_g := evalue(ast_node.condition,scope)
	 
	if value_g.type == Values.value_type.error_v: return value_g
	
	var size := ast_node.elifs.size()
	
	if value_g.value:
		
		for s in ast_node.body:
			
			var value := evalue(s,private_scope)
			
			if value.type == Values.value_type.error_v: return value
			elif value.type == Values.value_type.return_v: return value
			elif value.type == Values.value_type.break_v: return Values.mk_break()
			elif value.type == Values.value_type.continue_v: return Values.mk_continue()
		
		return Values.mk_if(true)
	
	elif size: 
		var value : Values.RunTimeValues = null
		
		for elif_s in ast_node.elifs:
			value = evalue(elif_s,scope)
			
			if value.type == Values.value_type.error_v: return value
			elif value.type == Values.value_type.if_v and value.is_true : break
			elif value.type == Values.value_type.break_v or value.type == Values.value_type.continue_v : return value
	#
	
	return Values.mk_if(false)
