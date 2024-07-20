class_name HandlerContainer extends RefCounted

static func number(lex: Lexer.LexerHandler, regex_m: RegExMatch) -> void :
	var number_match := regex_m.get_string(0)
	lex.advance(number_match.length())
	lex.create_token(Lexer.tk_type.NUMBER,number_match,0,regex_m.get_end(0))

static func identifier(lex: Lexer.LexerHandler, regex_m: RegExMatch) -> void :
	
	var identifier_match := regex_m.get_string(0)
	lex.advance(identifier_match.length())
	
	if Lexer.keywords.has(identifier_match):
		lex.create_token(Lexer.keywords[identifier_match],identifier_match,0,regex_m.get_end(0))
		return
	
	lex.create_token(Lexer.tk_type.IDENTIFIER,identifier_match,0,regex_m.get_end(0))

static func string(lex: Lexer.LexerHandler, regex_m: RegExMatch) -> void :
	var string_match := regex_m.get_string(0)
	lex.advance(string_match.length())
	lex.create_token(Lexer.tk_type.STRING,string_match.substr(1,string_match.length()-2).c_unescape(),0,regex_m.get_end(0))


static func skippable(lex: Lexer.LexerHandler, regex_m: RegExMatch) -> void:
	lex.advance(regex_m.get_end())

static  func general(lex: Lexer.LexerHandler,regex_m: RegExMatch,tk_type: int, value: String) -> void:
	lex.advance(value.length())
	lex.create_token(tk_type,value,0,regex_m.get_end(0))
