class_name ClydeInterpreter
extends IClydeInterpreter


func select_block(block_name : String = "", check_access : bool = false) -> bool:
	#assert(!block_name.is_empty() && anchors.has(block_name),
	#	"Block name was given but no such block exists!")
	if(!check_access):
		if anchors.has(block_name):
			memory.set_as_accessed(block_name)
			stack.initialise_stack(anchors[block_name])
		else:
			stack.initialise_stack(doc)
		return true
	else:
		if anchors.has(block_name) && can_access(block_name):
			memory.set_as_accessed(block_name)
			stack.initialise_stack(anchors[block_name])
			return true
		else:
			stack.initialise_stack(doc)
		return false


func get_variable(name : String):
	return memory.get_variable(name)


func set_random_block(check_access : bool = false) -> bool:
	return random_block_interpreter.set_random_block(check_access)


func set_variable(name, value):
	return memory.set_variable(name, value)


func clear_data() -> void:
	memory.clear()


func _initialise_blocks(doc : DocumentNode) -> void:
	for i in range(doc.blocks.size()):
		doc.blocks[i].node_index = i + 2
		anchors[doc.blocks[i].block_name] = doc.blocks[i]

