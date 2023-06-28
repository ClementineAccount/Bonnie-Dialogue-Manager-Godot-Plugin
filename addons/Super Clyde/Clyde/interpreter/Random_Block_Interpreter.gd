class_name RandomBlockInterpreter
extends MiscInterpreter


func set_random_block(check_access : bool = false) -> bool:
	randomize()
	var blocks : Array = _get_visible_blocks()
	blocks.shuffle()

	while(!blocks.is_empty()):
		if(interpreter.select_block(blocks.front().block_name, check_access)):
			return true
		else:
			blocks.pop_front()
	blocks = _get_fallback_blocks()
	if(!blocks.is_empty()):
		blocks.shuffle()
		interpreter.select_block(blocks.front().block_name, false)
		return true
	return false


func _get_visible_blocks() -> Array:
	return interpreter.anchors.values().filter(_check_if_random_block_not_accessed)


func _get_fallback_blocks() -> Array:
	return interpreter.anchors.values().filter(_check_for_fallback_blocks)


func _check_for_fallback_blocks(block : BlockNode):
	return block is RandomBlockNode && block.mode == 'fallback' 


func _check_if_random_block_not_accessed(block : BlockNode):
	if(block is RandomBlockNode):
		return block.mode != 'fallback' && !(block.mode == 'once' 
		&& memory.was_already_accessed(block.block_name))
	return false
