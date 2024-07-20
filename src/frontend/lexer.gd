class_name Lexer extends Node

enum tk_type {
	
	#tipos literais
	NUMBER,
	IDENTIFIER,
	STRING,
	
	# grupos ou operadores
	EQUALS, #=
	NOT_EQUALS,
	EQUAL_EQUALS,
	LESS_EQUALS,
	LESS,
	GREATER_EQUALS,
	GREATER,
	PLUS_EQUALS,
	MINUS_EQUALS,
	SLASH_EQUALS,
	STAR_EQUALS,
	
	OPEN_PAREN,
	CLOSE_PAREN,
	PLUS,
	MINUS,
	SLASH,
	STAR,
	SEMI_COLAN,
	COMMA,
	DOT,
	COLON,
	OPEN_BRACE,
	CLOSE_BRACE,
	OPEN_BRACKET,
	CLOSE_BRACKET,
	
	#logicos
	AND,
	OR,
	
	
	#keywords
	#NILL, # nao definido # 6 # já o declaramos no ambiente
	LET, # 7,
	CONST,
	FN, #funcao
	RETURN,
	BREAK,
	CONTINUE,
	
	WHILE,
	IF,
	ELIF,
	ELSE,
	
	ERROR,
	EOF # caracter que marcao fim d ficheiro
}

##palavras chaves
const keywords := {
	'let' : tk_type.LET,
	'const': tk_type.CONST,
	'fn': tk_type.FN,
	'while': tk_type.WHILE,
	'if': tk_type.IF,
	'elif': tk_type.ELIF,
	'else': tk_type.ELSE,
	'return': tk_type.RETURN,
	'break': tk_type.BREAK,
	'continue': tk_type.CONTINUE,
	'and': tk_type.AND,
	'or': tk_type.OR
}


#funcao que guarda os padroes a serem procurados no source code
class  RegexPattern:
	var regex_match : RegExMatch
	var handler_callable : Callable #guarda o tratador ou manipulador
	var regex_pattern : String #guarda o padrao a ser procurado


#analisador do codigo fonte
class LexerHandler:
	var patterns : Array[RegexPattern] #guarda todos padroes a serem procurados
	var tokens : Array[Token]
	var source_code : String
	var src_len : int
	var pos : int
	
	
	#avanca de acordo a correspondencia
	func advance(amount: int) -> void:
		pos += amount
	
	#posicao actual do cursor
	func at() -> String:
		return source_code[pos]
	
	#devolve a string restante
	func remainder() -> String:
		return source_code.right(src_len-pos)
	
	func at_end() -> bool:
		return pos >= src_len
	
	#cria tokens e adiciona na pilha
	func create_token (tk_type: int, value: String, line: int, colum: int) -> void:
		var tk := Token.new(tk_type,value,line,colum)
		tokens.append(tk)
	
	func lexer_error () -> void:
		assert(false,'[lexer] --> unrecognized token near \"%s\"'%remainder())
	



func tokenize(source_code :String) -> Array[Token]:
	
	var lexer_handler := create_lexer(source_code)
	var regex_t := RegEx.new()
	
	
	while  not lexer_handler.at_end():
		
		# caso seja falso, entao algum padrao nao registrado foi encontrado
		var matched := false
		
		for p: RegexPattern in lexer_handler.patterns:
			
			regex_t.clear()
			regex_t.compile(p.regex_pattern)
			p.regex_match = regex_t.search(lexer_handler.remainder())
			
			# verifica se correspondeu e se for no inicio
			if p.regex_match and p.regex_match.get_start(0) == 0:
				p.handler_callable.call(lexer_handler,p.regex_match)
				matched = true
				break
		
		if not matched: 
			regex_t.clear()
			lexer_handler.lexer_error()
		
	
	regex_t.clear()
	lexer_handler.create_token(tk_type.EOF,'EOF',0,0) #marca o fim do codigo
	
	return lexer_handler.tokens



func search_functions(source_code : String) -> String:
	
	var regex_t := RegEx.new()
	var source_code_n := ''
	
	regex_t.compile('fn[ ]+\\w+\\s*?\\(.*?\\)\\s*?{((.?\\s?)*)};?')
	
	for math_t in regex_t.search_all(source_code):
		var function_stmt := math_t.get_string(0)
		source_code = source_code.replace(function_stmt,'')
		source_code_n += function_stmt
	
	source_code_n += source_code
	regex_t.clear()
	
	return source_code_n

func create_lexer(source_code: String) -> LexerHandler:
	
	
	
	var lexer := LexerHandler.new()
	lexer.source_code = search_functions(source_code)
	lexer.src_len = source_code.length()
	lexer.pos = 0
	
	var basic_pattern := {
		"\\s+": HandlerContainer.skippable,
		"#.*":HandlerContainer.skippable,
		"\\d+(\\.\\d+)?\\b": HandlerContainer.number,
		"'.*?'": HandlerContainer.string,
		"[a-zA-Z_][a-zA-Z0-9_]*": HandlerContainer.identifier
		}
	
	
	for p in basic_pattern:
		
		var regex_p := RegexPattern.new()
		var basic_handler : Callable = basic_pattern[p]
		
		regex_p.handler_callable = basic_handler
		regex_p.regex_pattern = p
		
		lexer.patterns.append(regex_p)
	
	var pattern := {
		"\\[": HandlerContainer.general.bind(tk_type.OPEN_BRACKET,"["),
		"\\]": HandlerContainer.general.bind(tk_type.CLOSE_BRACKET,"]"),
		"\\{": HandlerContainer.general.bind(tk_type.OPEN_BRACE,"{"),
		"\\}": HandlerContainer.general.bind(tk_type.CLOSE_BRACE,"}"),
		"\\(": HandlerContainer.general.bind(tk_type.OPEN_PAREN,"("),
		"\\)": HandlerContainer.general.bind(tk_type.CLOSE_PAREN,")"),
		"==":  HandlerContainer.general.bind(tk_type.EQUAL_EQUALS,"=="),
		"!=":  HandlerContainer.general.bind(tk_type.NOT_EQUALS,"!="),
		"=":   HandlerContainer.general.bind(tk_type.EQUALS,"="),
		#"!": default_handler.bind(Tokenizer.TK_TYPES.NOT,"!"),
		"<=":  HandlerContainer.general.bind(tk_type.LESS_EQUALS,"<="),
		"<":   HandlerContainer.general.bind(tk_type.LESS,"<"),
		">=":  HandlerContainer.general.bind(tk_type.GREATER_EQUALS,">="),
		">":   HandlerContainer.general.bind(tk_type.GREATER,">"),
		"\bor\b":  HandlerContainer.general.bind(tk_type.OR,"or"),
		"\band\b": HandlerContainer.general.bind(tk_type.AND,"and"),
		#"\\.\\.": default_handler.bind(Tokenizer.TK_TYPES.DOT_DOT,".."),
		"\\.": HandlerContainer.general.bind(tk_type.DOT,"."),
		";": HandlerContainer.general.bind(tk_type.SEMI_COLAN,";"),
		":": HandlerContainer.general.bind(tk_type.COLON,":"),
		#"\\?": default_handler.bind(Tokenizer.TK_TYPES.QUESTION,"?"),
		",": HandlerContainer.general.bind(tk_type.COMMA,","),
		#"\\+\\+": default_handler.bind(Tokenizer.TK_TYPES.PLUS_PLUS,"++"),
		#"\\-\\-": default_handler.bind(Tokenizer.TK_TYPES.MINUS_MINUS,"--"),
		
		"\\+=": HandlerContainer.general.bind(tk_type.PLUS_EQUALS,"+="),
		"\\-=": HandlerContainer.general.bind(tk_type.MINUS_EQUALS,"-="),
		"\\*=": HandlerContainer.general.bind(tk_type.STAR_EQUALS,"*="),
		"\\/=": HandlerContainer.general.bind(tk_type.SLASH_EQUALS,"/="),
		
		"\\+": HandlerContainer.general.bind(tk_type.PLUS,"+"),
		"\\-": HandlerContainer.general.bind(tk_type.MINUS,"-"),
		"\\/": HandlerContainer.general.bind(tk_type.SLASH,"/"),
		"\\*": HandlerContainer.general.bind(tk_type.STAR,"*"),
		"%": HandlerContainer.general.bind(tk_type.SLASH,"%"),
	}
	
	
	for p in pattern:
		
		var regex_p := RegexPattern.new()
		var p_callable : Callable = pattern[p]
		
		regex_p.handler_callable = p_callable
		regex_p.regex_pattern = p
		
		lexer.patterns.append(regex_p)
	
	
	
	return lexer

static func tk_string(id: int) -> String:
	return tk_type.keys()[id]
