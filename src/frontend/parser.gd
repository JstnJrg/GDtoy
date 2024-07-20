class_name Parser extends Node

class ParserHandler:
	
	var is_function := false #checa se o return esta dentro da funcao
	var is_loop := false #testa se é um loop
	var is_condictional_if := false #testa se é um codicional
	var parser_error := ErrorHandler.parser_start
	
	var tokens :Array[Token]
	
	func not_eof() -> bool:
		return at().type != Lexer.tk_type.EOF
	
	func at() -> Token:
		return tokens[-1]
	
	func eat() -> Token:
		return tokens.pop_back()
	
	func mk_error_token(value: String) -> Token:
		return Token.new(Lexer.tk_type.ERROR,value,0,0)
	
	func expected(expected_type: Lexer.tk_type, _err: String) -> Token:
		
		var tk_corrent := eat()
		
		if tk_corrent and tk_corrent.type != expected_type:
			tk_corrent = mk_error_token(parser_error+'expecting %s, found %s. %s'%[Lexer.tk_string(expected_type),Lexer.tk_string(tk_corrent.type),_err])
		
		return tk_corrent
	
	func has_tokens() -> bool:
		return tokens.size() > 1
	
	func clear_tokens () -> void:
		tokens.clear()
	
	# atribuicao
	# objecto/dicionario
	# adicicao
	# multiplicacao
	# dados primarios
	
	func parse_stmt () -> Ast.Stmt:
		
		var current_tk := at()
		
		match  current_tk.type:
			
			#declaracao de variaveis
			Lexer.tk_type.LET:
				return parse_var_declaration()
			
			Lexer.tk_type.CONST:
				return parse_var_declaration()
			
			Lexer.tk_type.FN:
				return parse_function_declaration()
			
			Lexer.tk_type.WHILE:
				return parse_while_expression()
			
			Lexer.tk_type.IF:
				return parse_if_expression()
			
			Lexer.tk_type.ELIF:
				return parse_elif_expression()
			
			Lexer.tk_type.ELSE:
				return parse_else_expression()
			
			Lexer.tk_type.RETURN:
				return parse_return_expression()
			
			Lexer.tk_type.BREAK:
				return parse_break_expression()
			
			Lexer.tk_type.CONTINUE:
				return parse_continue_expression()
			#expressoes basicas
			_: 
				var result := parse_expression()
				#no final de cada sentenca
				var err_token := expected(Lexer.tk_type.SEMI_COLAN,'')
				result = Ast.mk_error_ast(err_token.value) if err_token.type == Lexer.tk_type.ERROR else result
				
				return result
		
		return Ast.Expr.new()
	
	
	
	#======================================
	
	func parse_function_declaration() -> Ast.Expr:
		
		
		#nao permite que funces sejam contruidas dentro de funcoes
		if is_function: return Ast.mk_error_ast(parser_error+'clousure is not supported, a function cannot be'+\
		' inside another function')
		
		#
		is_function = true
		
		eat()
		
		var name_t := expected(Lexer.tk_type.IDENTIFIER,'expected function name following \"fn\" keyword')
		if name_t.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(name_t.value)
		
		var args := parse_args_call_expression()
		
		var params : Array[String]
		
		for arg in args:
			
			if arg.type != Ast.node_type.Identifier:
				return Ast.mk_error_ast(parser_error+'inside function declaration expected parameters to be of type string')
			
			params.append(arg.symbol)
		
		var err_token := expected(Lexer.tk_type.OPEN_BRACE,'expected function body following declaration')
		if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		var body : Array[Ast.Stmt]
		
		while  not_eof() and at().type != Lexer.tk_type.CLOSE_BRACE:
			
			var data := parse_stmt()
			if data.type == Ast.node_type.ErrorLiteral: return data
			
			body.append(data)
		
		err_token = expected(Lexer.tk_type.CLOSE_BRACE,'closing brace expected function body following declaration')
		if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		err_token = expected(Lexer.tk_type.SEMI_COLAN,'semicolan expected function body following declaration')
		if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		var fn := Ast.FunctionDeclaration.new()
		fn.body = body
		fn.name_t = name_t.value
		fn.parameters = params
		
		
		#
		is_function = false
		
		return fn
	
	func parse_return_expression() -> Ast.Expr:
		
		if not is_function:  return Ast.mk_error_ast(parser_error+'return keyword is just allowed inside function.')
		
		eat()
		
		# verifica se nao há nada, para podem retornar
		if at().type == Lexer.tk_type.SEMI_COLAN:
			eat()
			var return_data := Ast.ReturnExpr.new()
			return return_data
		
		
		var return_ := parse_expression()
		
		if return_.type == Ast.node_type.ErrorLiteral: return return_
		
		var return_data := Ast.ReturnExpr.new()
		return_data.retun = return_
		
		var err_token := expected(Lexer.tk_type.SEMI_COLAN,'missing semicolan after return expression')
		if err_token.type == Lexer.tk_type.ERROR: Ast.mk_error_ast(err_token.value)
		
		return return_data
	
	func parse_break_expression() -> Ast.Expr:
		
		if not is_loop: return Ast.mk_error_ast(parser_error+'break keyword is just allowed inside loops.')
		
		eat()
		
		var break_ast := Ast.BreakExpr.new()
		var err_token := expected(Lexer.tk_type.SEMI_COLAN,'missing semicolan after break expression')
		if err_token.type == Lexer.tk_type.ERROR: Ast.mk_error_ast(err_token.value)
		
		return break_ast
	
	func parse_continue_expression() -> Ast.Expr:
		
		if not is_loop: return Ast.mk_error_ast(parser_error+'continue keyword is just allowed inside loops.')
		
		eat()
		
		var continue_ast := Ast.ContinueExpr.new()
		var err_token := expected(Lexer.tk_type.SEMI_COLAN,'missing semicolan after continue expr')
		if err_token.type == Lexer.tk_type.ERROR: Ast.mk_error_ast(err_token.value)
		
		return continue_ast
	
	func parse_var_declaration() -> Ast.Expr:
		
		var is_constant := true if eat().type == Lexer.tk_type.CONST else false
		
		var identifier_name := expected(Lexer.tk_type.IDENTIFIER,'')
		if identifier_name.type == Lexer.tk_type.ERROR: Ast.mk_error_ast(identifier_name.value)
		
		## para LET ou VAR X;
		#as variaveis podem ser declaradas como var x
		if at().type == Lexer.tk_type.SEMI_COLAN:
			eat()
			
			if is_constant:
				return Ast.mk_error_ast(parser_error+'must assign value to constant expression. No value provided')
			
			var var_data := Ast.VarDeclaration.new()
			var_data.identifier = identifier_name.value
			var_data.constant = is_constant
			var_data.value = null
			
			return var_data
		
		## PARA CONST ou LET x = 443;
		var err_token := expected(Lexer.tk_type.EQUALS,'')
		if err_token.type == Lexer.tk_type.ERROR: Ast.mk_error_ast(err_token.value)
		
		var var_data := Ast.VarDeclaration.new()
		var_data.identifier = identifier_name.value
		var_data.constant = is_constant
		var_data.value = parse_expression()
		
		err_token = expected(Lexer.tk_type.SEMI_COLAN,'')
		if err_token.type == Lexer.tk_type.ERROR: Ast.mk_error_ast(err_token.value)
		
		return var_data
	
	func  parse_while_expression() -> Ast.Expr:
		
		
		if not is_function: 
			return Ast.mk_error_ast(parser_error+'conditional loops are only allowed inside functions.')
		
		#
		is_loop = true
		
		eat()
		var err_token := expected(Lexer.tk_type.OPEN_PAREN,'missing open paren in while expr')
		if err_token.type == Lexer.tk_type.ERROR: Ast.mk_error_ast(err_token.value)
		#sem suporte a array dentro do while
		
		var condiction := parse_expression()
		if condiction.type == Ast.node_type.ErrorLiteral: return condiction
		
		
		err_token = expected(Lexer.tk_type.CLOSE_PAREN,'missing close paren in while expr')
		if err_token.type == Lexer.tk_type.ERROR: Ast.mk_error_ast(err_token.value)
		
		err_token = expected(Lexer.tk_type.OPEN_BRACE,'missing open brace in while expr')
		if err_token.type == Lexer.tk_type.ERROR: Ast.mk_error_ast(err_token.value)
		
		var while_ast := Ast.WhileExpr.new()
		var body : Array[Ast.Stmt]
		
		while  not_eof() and at().type != Lexer.tk_type.CLOSE_BRACE:
			var stmt := parse_stmt()
			if stmt.type == Ast.node_type.ErrorLiteral : return stmt
			body.append(stmt)
		
		err_token = expected(Lexer.tk_type.CLOSE_BRACE,'missing close brace in while expr')
		if err_token.type == Lexer.tk_type.ERROR: Ast.mk_error_ast(err_token.value)
		
		err_token = expected(Lexer.tk_type.SEMI_COLAN,'missing semicolan after while expr')
		if err_token.type == Lexer.tk_type.ERROR: Ast.mk_error_ast(err_token.value)
		
		
		while_ast.condition = condiction
		while_ast.body = body
		
		#
		is_loop = false
		
		return while_ast
	
	func  parse_if_expression() -> Ast.Expr:
		
		if not is_function: 
			return Ast.mk_error_ast(parser_error+'if conditional is only allowed inside functions.')
		
		# é um condicional
		is_condictional_if = true
		
		eat()
		var err_token := expected(Lexer.tk_type.OPEN_PAREN,'missing open paren sentence')
		if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		#sem suporte a array dentro do while
		var condiction := parse_expression()
		var body : Array[Ast.Stmt]
		
		err_token = expected(Lexer.tk_type.CLOSE_PAREN,'missing close paren sentence')
		if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		err_token = expected(Lexer.tk_type.OPEN_BRACE,'missing open brace sentence')
		if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		while  not_eof() and at().type != Lexer.tk_type.CLOSE_BRACE:
			
			var stmt := parse_stmt()
			if stmt.type == Ast.node_type.ErrorLiteral : return stmt
			
			body.append(stmt)
		
		err_token = expected(Lexer.tk_type.CLOSE_BRACE,'missing close brace sentence')
		if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		err_token = expected(Lexer.tk_type.SEMI_COLAN,'missing semicolan sentence')
		if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		var if_ast := Ast.IfExpr.new()
		if_ast.condition = condiction
		if_ast.body = body
		
		if at().type != Lexer.tk_type.ELSE and at().type != Lexer.tk_type.ELIF: is_condictional_if = false
		
		else :
			while not_eof() and  at().type == Lexer.tk_type.ELSE or at().type == Lexer.tk_type.ELIF:
				
				var stmt := parse_stmt()
				if stmt.type == Ast.node_type.ErrorLiteral : return stmt
				
				if_ast.elifs.append(stmt)
		
		return if_ast
	
	func  parse_elif_expression() -> Ast.Expr:
		
		if not is_function or not is_condictional_if: 
			return Ast.mk_error_ast(parser_error+'elif conditional is only allowed inside functions or after if sentece.')
		
		eat()
		
		var err_token := expected(Lexer.tk_type.OPEN_PAREN,'missing open paren in sentence')
		if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		#sem suporte a array dentro do while
		var condiction := parse_expression()
		var body : Array[Ast.Stmt]
		
		err_token = expected(Lexer.tk_type.CLOSE_PAREN,'missing close paren in sentence')
		if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		err_token = expected(Lexer.tk_type.OPEN_BRACE,'missing open brace in sentence')
		if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		while  not_eof() and at().type != Lexer.tk_type.CLOSE_BRACE:
			
			var stmt := parse_stmt()
			if stmt.type == Ast.node_type.ErrorLiteral: return stmt
			
			body.append(stmt)
		
		err_token = expected(Lexer.tk_type.CLOSE_BRACE,'missing close brace in sentence')
		if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		err_token = expected(Lexer.tk_type.SEMI_COLAN,'missing semicolan in sentence')
		if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		
		var elif_ast := Ast.IfExpr.new()
		elif_ast.condition = condiction
		elif_ast.body = body
		
		if at().type != Lexer.tk_type.ELSE and at().type != Lexer.tk_type.ELIF:
			is_condictional_if = false
		
		return elif_ast
	
	func parse_else_expression() -> Ast.Expr:
		
		if not is_condictional_if:
			return Ast.mk_error_ast(parser_error+'else conditional is only allowed after if sentence.')
		
		eat()
		
		var err_token := expected(Lexer.tk_type.OPEN_BRACE,'missing open brace in sentece')
		if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		
		var body : Array[Ast.Stmt]
		
		while  not_eof() and at().type != Lexer.tk_type.CLOSE_BRACE:
			
			var stmt := parse_stmt()
			if stmt.type == Ast.node_type.ErrorLiteral: return stmt
			
			body.append(stmt)
		
		err_token = expected(Lexer.tk_type.CLOSE_BRACE,'[parser] --> missing close brace in sentence')
		if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		err_token = expected(Lexer.tk_type.SEMI_COLAN,'[parser] --> missing semicolan in sentence')
		if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		var else_expr := Ast.IfExpr.new()
		var n_condiction := Ast.NumericLiteral.new()
		n_condiction.value = 1
		
		else_expr.condition = n_condiction
		else_expr.body = body
		#
		is_condictional_if = false
		
		return else_expr
	
	
	func parse_expression() -> Ast.Expr:
		return parse_assignment_expression()
	
	func parse_assignment_expression() -> Ast.Expr:
		
		var left := parse_logicians_expression()
		if left.type == Ast.node_type.ErrorLiteral: return left
		
		if at().type == Lexer.tk_type.EQUALS:
			
			eat()
			# nao permite atribuicoes como var x=4=4
			var value := parse_logicians_expression()#parse_assignment_expr()
			var ast_node := Ast.AssignmentExpr.new()
			
			if value.type == Ast.node_type.ErrorLiteral: return value
			
			ast_node.value = value
			ast_node.assigne = left #ou seja, uma variavel
			
			left = ast_node
		
		return left
	
	func parse_logicians_expression() -> Ast.Expr:
		
		var left := parse_equality_expression()
		if left.type == Ast.node_type.ErrorLiteral: return left
		
		var logicians := [Lexer.tk_type.AND,Lexer.tk_type.OR]
		
		#permite expressoes 4 and 5 or true
		while not_eof() and logicians.has(at().type):
			
			var operator := eat().value
			var right := parse_equality_expression()
			if right.type == Ast.node_type.ErrorLiteral: return right
			
			var equality_ast := Ast.EqualityExpr.new()
			
			
			
			equality_ast.letf = left
			equality_ast.operator = operator
			equality_ast.right = right
			
			left = equality_ast
		
		return left
	
	func parse_equality_expression() -> Ast.Expr:
		
		var left := parse_object_expression()
		if left.type == Ast.node_type.ErrorLiteral: return left
		
		var operators := [Lexer.tk_type.EQUAL_EQUALS,Lexer.tk_type.NOT_EQUALS,Lexer.tk_type.LESS_EQUALS,\
		Lexer.tk_type.LESS,Lexer.tk_type.GREATER_EQUALS,Lexer.tk_type.GREATER
		]
		
		#permite expressoes 4 == 5 == true
		while not_eof() and operators.has(at().type):
			
			var operator := eat().value
			var right := parse_object_expression()
			
			if right.type == Ast.node_type.ErrorLiteral: return right
			
			var equality_ast := Ast.EqualityExpr.new()
			equality_ast.letf = left
			equality_ast.operator = operator
			equality_ast.right = right
			left = equality_ast
		
		
		return left
	
	func parse_object_expression() -> Ast.Expr:
		
		if at().type != Lexer.tk_type.OPEN_BRACE:
			return parse_array_expression()
		
		eat()
		
		var properties : Array[Ast.Property]
		var dicionary := Ast.ObjectLiteral.new()
		var err_token : Token = null
		
		while not_eof() and at().type != Lexer.tk_type.CLOSE_BRACE:
			
			var key := expected(Lexer.tk_type.IDENTIFIER,'dictionary literal key expected')
			if key.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(key.value)
			
			var property_node := Ast.Property.new()
			
			if Lexer.keywords.has(key):
				return Ast.mk_error_ast(parser_error+'expected expression as object key. found %s'%[key])
			
			#{a,g,r}
			if at().type == Lexer.tk_type.COMMA:
				eat()
				property_node.key = key.value
				property_node.value = null
				properties.append(property_node)
				continue
			
			#{key}
			elif at().type == Lexer.tk_type.CLOSE_BRACE:
				property_node.key = key.value
				property_node.value = null
				properties.append(property_node)
				continue
			
			#{a:5}
			err_token = expected(Lexer.tk_type.COLON,'missing colon following in object')
			if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
			
			#permite ter objectos dentro do dicionario
			var value := parse_expression()
			if value.type == Ast.node_type.ErrorLiteral: return value
			
			property_node.key = key.value
			property_node.value = value
			properties.append(property_node)
			
			#{a:4,}
			if at().type != Lexer.tk_type.CLOSE_BRACE:
				err_token = expected(Lexer.tk_type.COMMA,'missing comma in object')
				if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
				continue
			
		
		err_token = expected(Lexer.tk_type.CLOSE_BRACE,'missing brace in object')
		if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		dicionary.properties = properties
		
		return dicionary
	
	func parse_array_expression() -> Ast.Expr:
		
		if at().type != Lexer.tk_type.OPEN_BRACKET:
			return parse_equality_assignment_expression()
		
		eat()
		
		var ast_array := Ast.ArrayLiteral.new()
		var err_token : Token = null
		
		while  not_eof() and at().type != Lexer.tk_type.CLOSE_BRACKET:
			
			var tk_current := at()
			
			if tk_current.type != Lexer.tk_type.NUMBER and tk_current.type != Lexer.tk_type.IDENTIFIER:
				err_token = expected(Lexer.tk_type.IDENTIFIER,'array elements must be a number or identifier')
				if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
			
			var element := parse_assignment_expression()
			if element.type == Ast.node_type.ErrorLiteral: return element
			
			ast_array.properties.append(element)
			
			if at().type != Lexer.tk_type.CLOSE_BRACKET:
				err_token = expected(Lexer.tk_type.COMMA,'array elements must be separeted by coma')
				if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		err_token = expected(Lexer.tk_type.CLOSE_BRACKET,'array must terminated with \"]\"')
		if err_token.type == Lexer.tk_type.ERROR: return Ast.mk_error_ast(err_token.value)
		
		return ast_array
	
	func parse_equality_assignment_expression () -> Ast.Expr:
		
		if at().type != Lexer.tk_type.IDENTIFIER:
			return parse_additive_expression()
		
		var left := parse_additive_expression()
		if left.type == Ast.node_type.ErrorLiteral: return left
		
		var operators := [Lexer.tk_type.PLUS_EQUALS,Lexer.tk_type.MINUS_EQUALS,\
		Lexer.tk_type.STAR_EQUALS,Lexer.tk_type.SLASH_EQUALS]
		
		var ast_equality_assig := Ast.EqualityAssignExpr.new()
		
		while  not_eof() and operators.has(at().type):
			
			ast_equality_assig.left = left
			ast_equality_assig.operator = eat().value
			
			var right := parse_additive_expression()
			if right.type == Ast.node_type.ErrorLiteral: return right
			
			ast_equality_assig.right = right
			left = ast_equality_assig
		
		return left
	
	func parse_additive_expression() -> Ast.Expr:
		
		var left := parse_multiplicative_expression()
		
		if left.type == Ast.node_type.ErrorLiteral: return left
		
		#operator
		var plus := Lexer.tk_type.PLUS
		var minus := Lexer.tk_type.MINUS
		
		while at().type == plus or at().type == minus:
			
			var operator := eat()
			var right := parse_multiplicative_expression()
			
			if right.type == Ast.node_type.ErrorLiteral: return right
			
			var binary_node := Ast.BinaryExpr.new()
			
			binary_node.left = left
			binary_node.operator = operator.value
			binary_node.right = right
			
			#para retornar na expressao acima
			# ou seja, vai armazenar o resultado final da
			# expressao a esquerda
			
			left = binary_node
		
		
		return left
	
	func parse_multiplicative_expression() -> Ast.Expr:
		
		var left := parse_call_member_expression()
		if left.type == Ast.node_type.ErrorLiteral: return left
		
		#operator
		var star := Lexer.tk_type.STAR
		var slash := Lexer.tk_type.SLASH
		
		while  at().type == star or at().type == slash:
			
			#retira a operacao
			
			var operator := eat()
			var right := parse_call_member_expression()
			
			if right.type == Ast.node_type.ErrorLiteral: return right
			
			var binary_node := Ast.BinaryExpr.new()
			
			binary_node.left = left
			binary_node.operator = operator.value
			binary_node.right = right
			
			#para retornar na expressao acima
			# ou seja, vai armazenar o resultado final da
			# expressao a esquerda 
			#ex: bin+5
			
			left = binary_node
		
		
		return left
	
	func parse_call_member_expression() -> Ast.Expr:
		
		var member := parse_member_expression()
		
		if member.type == Ast.node_type.ErrorLiteral: return member
		elif at().type == Lexer.tk_type.OPEN_PAREN: return parse_call_expression(member)
		
		return member
	
	func parse_call_expression(caller: Ast.Expr) -> Ast.Expr:
		
		var call_expr := Ast.CallExpr.new()
		call_expr.caller = caller
		call_expr.args = parse_args_call_expression()
		
		return call_expr
	
	func parse_args_call_expression() -> Array[Ast.Expr]:
		
		var err_token := expected(Lexer.tk_type.OPEN_PAREN,'expected open parenthesis in caller expression')
		var args : Array[Ast.Expr]
		
		if err_token.type == Lexer.tk_type.ERROR: return args
		
		if not_eof() and at().type != Lexer.tk_type.CLOSE_PAREN:
			args = parse_arguments_list()
		
		err_token = expected(Lexer.tk_type.CLOSE_PAREN,'missing closing parenthesis inside arguments list')
		
		if err_token.type == Lexer.tk_type.ERROR: return args
		
		return args
	
	func parse_arguments_list() -> Array[Ast.Expr]:
		
		var args : Array[Ast.Expr] = [parse_assignment_expression()]
		
		while  not_eof() and at().type == Lexer.tk_type.COMMA:
			eat()
			var value := parse_assignment_expression()
			
			if value.type == Ast.node_type.ErrorLiteral:
				args.append(value)
				return args
			
			args.append(value)
		
		return args
	
	
	func parse_member_expression() -> Ast.Expr:
		
		var identifier := parse_unary_expression()
		if identifier.type == Ast.node_type.ErrorLiteral: return identifier
		
		while at().type == Lexer.tk_type.DOT:
			
			if identifier.type != Ast.node_type.Identifier and identifier.type != Ast.node_type.MemberExpr:
				return Ast.mk_error_ast(parser_error+'cannot use dot operator without lhs being a identifier or member expression. found %s'%[Ast.node_string(identifier.type)])
			
			eat()
			
			var member := parse_unary_expression()
			if member.type == Ast.node_type.ErrorLiteral: return member
			
			elif member.type != Ast.node_type.Identifier:
				return Ast.mk_error_ast(parser_error+'cannot use dot operator without rhs being a identifier or member expression. found %s'%[Ast.node_string(member.type)])
			
			var object := Ast.MemberExpr.new()
			object.object = identifier
			object.property = member
			object.computed = false
			
			identifier = object
		
		
		return identifier
	
	func parse_unary_expression() -> Ast.Expr:
		
		var operations := [Lexer.tk_type.MINUS,Lexer.tk_type.PLUS]
		
		if operations.has(at().type):
			
			var t := eat() #
			var operator := '*'
			var right := parse_unary_expression()
			
			if right.type == Ast.node_type.ErrorLiteral: return right
			
			var number := Ast.NumericLiteral.new()
			var bin_node := Ast.BinaryExpr.new()
			
			number.value = -1 if t.type == Lexer.tk_type.MINUS else 1
			
			
			bin_node.left = number
			bin_node.operator = operator
			bin_node.right = right
			
			return bin_node
		
		return parse_primary_expression()
	
	func parse_primary_expression() -> Ast.Expr:
		
		var tk_current := at()
		
		match  tk_current.type:
			
			Lexer.tk_type.OPEN_PAREN:
				eat() 
				
				var result := parse_expression()
				var tk_error  := expected(Lexer.tk_type.CLOSE_PAREN,'')
				
				if tk_error.type == Lexer.tk_type.ERROR:
					result = Ast.mk_error_ast(parser_error+tk_error.value)
				elif not has_tokens():
					result = Ast.mk_error_ast(parser_error+'invalid expression')
				
				return result
			
			Lexer.tk_type.NUMBER:
				
				var number := Ast.NumericLiteral.new()
				number.value = eat().value.to_float() 
				
				return number if has_tokens() else Ast.mk_error_ast(parser_error+'invalid expression')
			
			Lexer.tk_type.IDENTIFIER:
				var identifier := Ast.Identifier.new()
				identifier.symbol = eat().value
				return identifier if has_tokens() else Ast.mk_error_ast(parser_error+'invalid expression')
			
			Lexer.tk_type.STRING:
				var string := Ast.StringLiteral.new()
				string.value = eat().value
				return string if has_tokens() else Ast.mk_error_ast(parser_error+'invalid expression')
			
			_:
				return Ast.mk_error_ast(parser_error+'unexpected token during parsing %s'%tk_current.value)




func produce_AST(tokens : Array[Token]) -> Ast.Program:
	
	var parser_handler := ParserHandler.new()
	var program := Ast.Program.new()
	
	parser_handler.tokens = tokens
	
	while parser_handler.not_eof():
		
		var stmt := parser_handler.parse_stmt()
		
		if stmt.type == Ast.node_type.ErrorLiteral:
			printerr(stmt.get_error())
			program.body.clear()
			break
		
		program.body.append(stmt)
	
	return program
