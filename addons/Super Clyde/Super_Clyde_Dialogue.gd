class_name SuperClydeDialogue
extends IClydeDialogue


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func load_dialogue(file_name : String, block  : String= "", check_access :bool = false) -> void:
	var fileDict : Dictionary = _load_file(_get_file_path(file_name))
	_interpreter = SuperClydeInterpreter.new()
	_interpreter.init(fileDict, {
		"id_suffix_lookup_separator": _config_id_suffix_lookup_separator(),
	})
	_interpreter.connect("variable_changed",Callable(self,"_trigger_variable_changed"))
	_interpreter.connect("event_triggered",Callable(self,"_trigger_event_triggered"))
	if !block.is_empty():
		_interpreter.select_block(block,check_access)
