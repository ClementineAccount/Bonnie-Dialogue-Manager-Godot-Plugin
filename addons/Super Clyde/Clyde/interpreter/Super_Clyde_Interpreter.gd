class_name SuperClydeInterpreter
extends IClydeInterpreter

var current_file : String = ""


func select_block(block_name : String = "", check_access : bool = false) -> bool:
	if(block_name.contains(".")):
		if(!check_access):
			if anchors.has(block_name):
				memory.set_as_accessed(block_name)
				stack.initialise_stack(anchors[block_name])
				current_file = block_name.split(".", false)[0]
			else:
				stack.initialise_stack(doc)
			return true
		else:
			if anchors.has(block_name) && can_access(block_name):
				memory.set_as_accessed(block_name)
				stack.initialise_stack(anchors[block_name])
				current_file = block_name.split(".", false)[0]
				return true
			else:
				stack.initialise_stack(doc)
			return false
	else:
		return select_block(current_file + "." + block_name, check_access)


func get_variable(name : String):
	if(name.begins_with("@") || name.contains(".")):
		return memory.get_variable(name)
	
	return memory.get_variable(current_file + "." +name)


func set_random_block(check_access : bool = false) -> bool:
	return random_block_interpreter.set_random_block(check_access)


func set_variable(name, value):
	if(name.begins_with("@") || name.contains(".")):
		return memory.set_variable(name, value)
	return memory.set_variable(current_file + "." +name, value)


func clear_data() -> void:
	memory.clear()


func _initialise_blocks(doc : DocumentNode) -> void:
	for i in range(doc.blocks.size()):
		doc.blocks[i].node_index = i + 2
		anchors[current_file+"." + doc.blocks[i].block_name] = doc.blocks[i]
