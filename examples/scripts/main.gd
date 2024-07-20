extends Control

@onready var run: Button = $HBoxContainer/run
@onready var code_edit: CodeEdit = $CodeEdit
@onready var label: Label = $ScrollContainer/Label

var lexer := Lexer.new()
var parser := Parser.new()
var interpreter := Interpreter.new()
var synthaxhighlighter := CodeHighlighter.new()


func _ready() -> void:
	
	add_child(lexer)
	add_child(parser)
	add_child(interpreter)
	
	editor_hightlights()
	run.pressed.connect(run_lexer)



func editor_hightlights() -> void:
	
	synthaxhighlighter.symbol_color = Color(0.82, 0.677, 0.369)
	synthaxhighlighter.number_color = Color(0.82, 0.677, 0.369)
	var kw := lexer.keywords.duplicate()
	kw.merge({'null': 0, 'false': 0, 'true': 0,'PI': 0,'TAU':0},false)
	
	for k in kw:
		synthaxhighlighter.add_keyword_color(k,Color.RED)
	
	code_edit.syntax_highlighter = synthaxhighlighter

func run_lexer () -> void:
	
	var global_scope := EnvironmentHandler.create_global_scope()
	var tokens := lexer.tokenize(code_edit.text)
	
	label.text = ''
	for t in tokens: label.text += 'type: %s\nvalue: %s\n'%[t.value,Lexer.tk_string(t.type)]
	
	tokens.reverse()
	
	var program := parser.produce_AST(tokens)
	var data := interpreter.evalue(program,global_scope)
	
	global_scope.free_scope()
	
