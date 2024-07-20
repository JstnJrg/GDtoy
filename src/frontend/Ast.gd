class_name Ast extends Node

# tipos de nos da arvore
enum node_type {
	
	#sentencas
	Program,
	VarDeclarationStmt,
	FunctionDeclaration, #vai permitir let foo = func
	
	#Expressoes
	AssignmentExpr,
	EqualityExpr,
	EqualityAssignExpr,
	MemberExpr,
	CallExpr,
	
	#loops
	WhileExpr,
	IfExpr,
	ElifExpr,
	ElseExpr,
	
	ReturnExpr,
	BreakExpr,
	ContinueExpr,
	
	#Literais
	Property,
	ObjectLiteral,
	ArrayLiteral,
	NumericLiteral,
	StringLiteral,
	Identifier,
	BinaryExpr,
	
	ErrorLiteral
	}


#classe base das sentecas
class Stmt: var type : node_type

class Expr extends  Stmt: pass

class ErrorExpr extends  Expr:
	
	var error : String
	func _init(msg: String) -> void: 
		type = node_type.ErrorLiteral
		error = msg
	func get_error() -> String:
		return error

# é um array de sentencas
class Program extends  Stmt:
	var body : Array[Stmt]
	func _init() -> void: type = node_type.Program
	
	func free_data() -> void:
		body.clear()

# x = 10+9 é x poderia ser uma string
# x.foo = 10+9, x.foo é uma expressao
class AssignmentExpr extends Expr:
	var assigne : Expr #é uma expr para oferecer suporte a x.foo, acessibildade a membros
	var value : Expr
	func _init() -> void: type = node_type.AssignmentExpr

#tambem é usado para os logicos
class EqualityExpr extends Expr:
	var letf : Expr #é uma expr para oferecer suporte a x.foo, acessibildade a membros
	var operator: String
	var right : Expr
	func _init() -> void: type = node_type.EqualityExpr



class EqualityAssignExpr extends Expr:
	var left : Expr #é uma expr para oferecer suporte a x.foo, acessibildade a membros
	var operator: String
	var right : Expr
	func _init() -> void: type = node_type.EqualityAssignExpr

# contem dados recursivos
# e.g : 10+4; foo*bar (pode conter funcoes)
class  BinaryExpr extends Expr: 
	var left : Expr
	var right : Expr
	var operator : String
	func _init() -> void: type = node_type.BinaryExpr

# pode ser uma variavel, uma funcao
# e.g: foo, bar
class Identifier extends  Expr:
	var symbol : String #x, foo, boo
	func _init() -> void: type = node_type.Identifier

# é uma expressao de expressoes
class NumericLiteral extends  Expr:
	var value : float
	func _init() -> void: type = node_type.NumericLiteral

class StringLiteral extends  Expr:
	var value : String
	func _init() -> void: type = node_type.StringLiteral

class VarDeclaration extends  Expr:
	var constant: bool
	var identifier : String
	var value: Expr #let x; é indefinido
	func _init() -> void: type = node_type.VarDeclarationStmt

class FunctionDeclaration extends Expr:
	var parameters : Array[String]
	var name_t: String #para verificar se ja há no corrente scopo
	var body: Array[Stmt]
	func _init() -> void: type = node_type.FunctionDeclaration

class Property extends  Expr:
	var key : String
	var value : Expr
	func _init() -> void: type = node_type.Property

class ObjectLiteral extends  Expr:
	var properties : Array[Property]
	func _init() -> void: type = node_type.ObjectLiteral




class ArrayLiteral extends Expr:
	var properties : Array[Expr]
	func _init() -> void:
		type = node_type.ArrayLiteral


class  CallExpr extends Expr: 
	
	var args : Array[Expr]
	var caller : Expr
	
	func _init() -> void:
		type = node_type.CallExpr

class  MemberExpr extends Expr: 
	var object : Expr
	var property : Expr
	var computed : bool #foo['bar']
	
	func _init() -> void:
		type = node_type.MemberExpr

class WhileExpr extends Expr:
	var condition: Expr
	var body : Array[Stmt]
	func _init() -> void: type = node_type.WhileExpr

class IfExpr extends Expr:
	
	var loop_parent : Expr
	var condition: Expr
	var elifs : Array[IfExpr]
	var body : Array[Stmt]
	
	func _init() -> void: type = node_type.IfExpr

class ElseExpr extends Expr:
	var body : Array[Stmt]
	func _init() -> void: type = node_type.ElseExpr



class ReturnExpr extends Expr:
	var retun: Expr
	func _init() -> void: type = node_type.ReturnExpr

class BreakExpr extends Expr:
	func _init() -> void: type = node_type.BreakExpr

class ContinueExpr extends Expr:
	func _init() -> void: type = node_type.ContinueExpr



static func node_string(id: int) -> String:
	return node_type.keys()[id]

static func mk_error_ast(msg: String) -> ErrorExpr:
	return ErrorExpr.new(msg)
