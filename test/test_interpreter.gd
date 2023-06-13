extends GutTestFunctions


func test_simple_lines_file():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('simple_lines')

	var lines = [
		_line({ "value": "Dinner at Jack Rabbit Slim's:" }),
		_line({ "value": "Don’t you hate that?", "speaker": "Mia" }),
		_line({ "value": "What?", "speaker": "Vincent" }),
		_line({ "value": "Uncomfortable silences. Why do we feel it’s necessary to yak about bullshit in order to be comfortable?", "speaker": "Mia", "id": "145" }),
		_line({ "value": "I don’t know. That’s a good question.", "speaker": "Vincent" }),
		_line({ "value": "That’s when you know you’ve found somebody special. When you can just shut the fuck up for a minute and comfortably enjoy the silence.", "speaker": "Mia", "id": "123"}),
	]

	for line in lines:
		assert_eq_deep(ClydeParser.new().to_JSON_object(dialogue.get_content()), line)


func test_translate_files():
	TranslationServer.set_locale("pt_BR")
	var t = Translation.new()
	t.locale = "pt_BR"
	t.add_message("145", "Tradução")
	TranslationServer.add_translation(t)
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('simple_lines')

	var lines = [
		_line({  "value": "Dinner at Jack Rabbit Slim's:" }),
		_line({  "value": "Don’t you hate that?", "speaker": "Mia" }),
		_line({  "value": "What?", "speaker": "Vincent" }),
		_line({  "value": "Tradução", "speaker": "Mia", "id": "145" }),
		_line({  "value": "I don’t know. That’s a good question.", "speaker": "Vincent" }),
		_line({  "value": "That’s when you know you’ve found somebody special. When you can just shut the fuck up for a minute and comfortably enjoy the silence.", "speaker": "Mia", "id": "123"}),
	]

	for line in lines:
		assert_eq_deep(ClydeParser.new().to_JSON_object(dialogue.get_content()), line)

	TranslationServer.set_locale("en")


func _initialize_dictionary():
	var t = Translation.new()
	t.locale = "en"
	t.add_message("abc", "simple key")
	t.add_message("abc&P", "simple key with suffix 1")
	t.add_message("abc&P&S", "simple key with suffix 1 and 2")
	t.add_message("abc&S", "simple key with only suffix 2")
	t.add_message("abc__P", "this uses custom suffix")
	TranslationServer.add_translation(t)
	TranslationServer.set_locale("en")


func _initialize_interpreter_for_suffix_test():
	var interpreter = ClydeInterpreter.new()
	var content = _parse("This should be replaced $abc&suffix_1&suffix_2")
	interpreter.init(content)
	return interpreter


func test_id_suffix_returns_line_with_suffix_value():
	var interpreter = _initialize_interpreter_for_suffix_test()
	_initialize_dictionary()
	interpreter.set_variable("suffix_1", "P");

	assert_eq(interpreter.get_current_node().value, "simple key with suffix 1")


func test_id_suffix_returns_line_with_multiple_suffixes_value():
	var interpreter = _initialize_interpreter_for_suffix_test()
	_initialize_dictionary()
	interpreter.set_variable("suffix_1", "P");
	interpreter.set_variable("suffix_2", "S");

	assert_eq(interpreter.get_current_node().value, "simple key with suffix 1 and 2")


func test_id_suffix_ignores_suffix_if_variable_is_not_set():
	var interpreter = _initialize_interpreter_for_suffix_test()
	_initialize_dictionary()
	interpreter.set_variable("suffix_1", "S");

	assert_eq(interpreter.get_current_node().value, "simple key with only suffix 2")


func test_id_suffix_ignores_all_suffixes_when_variables_not_set():
	var interpreter = _initialize_interpreter_for_suffix_test()
	_initialize_dictionary()

	assert_eq(interpreter.get_current_node().value, "simple key")


func test_id_suffix_fallsback_to_id_without_prefix_when_not_found():
	var interpreter = _initialize_interpreter_for_suffix_test()
	_initialize_dictionary()

	interpreter.set_variable("suffix_1", "banana");

	assert_eq(interpreter.get_current_node().value, "simple key")


func test_id_suffix_works_with_options():
	var interpreter = ClydeInterpreter.new()
	var content = _parse("""
first topics $abc&suffix1
	* option 1 $abc&suffix2
		blah
	*
		blah $abc&suffix1&suffix2""")
	interpreter.init(content)

	_initialize_dictionary()

	interpreter.set_variable("suffix1", "P");
	interpreter.set_variable("suffix2", "S");
	var first_options = interpreter.get_current_node()
	assert_eq(first_options.value, "simple key with suffix 1")
	assert_eq(first_options.content[0].value, "simple key with only suffix 2")

	interpreter.choose(1);

	var second_options = interpreter.get_current_node();
	assert_eq(second_options.value, "simple key with suffix 1 and 2")


func test_interpreter_option_id_lookup_suffix():
	_initialize_dictionary()

	var interpreter = ClydeInterpreter.new()
	var content = _parse("This should be replaced $abc&suffix_1&suffix_2")
	interpreter.init(content, { "id_suffix_lookup_separator": "__" })
	interpreter.set_variable("suffix_1", "P");

	assert_eq(interpreter.get_current_node().value, "this uses custom suffix")


func test_options():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('options')


	var first_part = [
		_line({  "value": "what do you want to talk about?", "speaker": "npc" }),
		_options({ "content": [_option({ "name": "Life" }), _option({ "name": "The universe" }), _option({ "name": "Everything else...", "tags": ["some_tag"] })] }),
		]

	var life_option = [
		_line({  "value": "I want to talk about life!", "speaker": "player" }),
		_line({  "value": "Well! That's too complicated...", "speaker": "npc" }),
	]

	for line in first_part:
		var q = ClydeParser.new().to_JSON_object(dialogue.get_content())
		q.content = []
		line.content = []
		assert_eq_deep(q, line)

	dialogue.choose(0)

	for line in life_option:
		var q = ClydeParser.new().to_JSON_object(dialogue.get_content())
		assert_eq_deep(q, line)


func test_fallback_options():
	var interpreter = ClydeInterpreter.new()
	var content = _parse("*= a\n>= b\nend")
	interpreter.init(content)
	var q = ClydeParser.new().to_JSON_object(interpreter.get_current_node())
	q.content[0].content = []
	q.content[1].content = []
	assert_eq_deep(q, _options({ "content": [_option({ "mode" : "once","value": "a" }), _option({ "value": "b", "mode" : "fallback"}) ] }))
	interpreter.choose(0)
	assert_eq_deep(interpreter.get_current_node().value, "a")
	assert_eq_deep(interpreter.get_current_node().value, "end")
	interpreter.select_block()
	assert_eq_deep(ClydeParser.new().to_JSON_object(interpreter.get_current_node()), _line({  "value": "b" }))


func test_blocks_and_diverts():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('diverts', 'initial_dialog')


	var initial_dialogue = [
		_line({"value": "what do you want to talk about?", "speaker": "npc" }),
		_options({ "content": [_option({ "value": "Life" }),_option({ "mode" : "once","value": "The universe" }), _option({ "mode" : "once","value": "Everything else..." }), _option({"mode" : "once", "value": "Goodbye!" })] }),
	]

	var life_option = [
		_line({ "value": "I want to talk about life!", "speaker": "player" }),
		_line({  "value": "Well! That's too complicated...", "speaker": "npc" }),
		# back to initial dialogue
		_options({ "content": [_option({ "mode" : "once", "value": "The universe" }), _option({ "mode" : "once","value": "Everything else..." }), _option({ "mode" : "once","value": "Goodbye!" })] })
	]

	var everything_option = [
		_line({  "value": "What about everything else?", "speaker": "player" }),
		_line({ "value": "I don't have time for this...", "speaker": "npc" }),
		# back to initial dialogue
		_options({ "options": [_option({ "value": "The universe" }), _option({ "value": "Goodbye!" })] })
	]

	var universe_option = [
		_line({  "value": "I want to talk about the universe!", "speaker": "player" }),
		_line({ "value": "That's too complex!", "speaker": "npc" }),
		# back to initial dialogue
		_options({ "options": [_option({ "value": "Goodbye!" })] })
	]

	var goodbye_option = [
		_line({ "value": "See you next time!", "speaker": "player" }),
		null
	]

	for line in initial_dialogue:
		var q = ClydeParser.new().to_JSON_object(dialogue.get_content())
		q.content = []
		line.content = []
		assert_eq_deep(q, line)

	dialogue.choose(0)

	for line in life_option:
		var q = ClydeParser.new().to_JSON_object(dialogue.get_content())
		if(q.has("content")):
			q.content[0].content = []
			q.content[1].content = []
			q.content[2].content = []
		assert_eq_deep(q, line)
	dialogue.choose(1)

	for line in everything_option:
		var q = ClydeParser.new().to_JSON_object(dialogue.get_content())
		if(q.has("content")):
			q.content = []
		assert_eq_deep(q, line)
	dialogue.choose(0)

	for line in universe_option:
		var q = ClydeParser.new().to_JSON_object(dialogue.get_content())
		if(q.has("content")):
			q.content = []
			pass
		assert_eq_deep(q, line)
	dialogue.choose(0)

	for line in goodbye_option:
		var line_dic = ClydeParser.new().to_JSON_object(dialogue.get_content())
		if(line_dic.keys().size() == 0):
			assert_eq_deep(null, line)
		else:
			assert_eq_deep(line_dic, line)


func test_variations():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('variations')

	var sequence = ["Hello", "Hi", "Hey"]
	var random_sequence = ["Hello", "Hi", "Hey"]
	var once = ["nested example", "here I am"]
	var random_cycle = ["multiline example do you think it works?", "yep"]

	for _i in range(4):
		dialogue.start()
		var thing = ClydeParser.new().to_JSON_object(dialogue.get_content())
		# sequence
		assert_eq_deep(
			thing.value,
			sequence[0]
		)

		if sequence.size() > 1:
			sequence.pop_front()

		# random sequence
		var rs = ClydeParser.new().to_JSON_object(dialogue.get_content()).value
		assert_has(random_sequence, rs)
		if random_sequence.size() > 1:
			random_sequence.erase(rs)

		# once each
		if (once.size() != 0):
			var o = ClydeParser.new().to_JSON_object(dialogue.get_content()).value
			assert_has(once, o)
			once.erase(o)

		# random cycle
		var rc = ClydeParser.new().to_JSON_object(dialogue.get_content()).value
		assert_has(random_cycle, rc)
		random_cycle.erase(rc)
		if random_cycle.size() == 0:
			random_cycle = ["multiline example do you think it works?", "yep"]


func _test_variation_default_shuffle_is_cycle():
	var interpreter = ClydeInterpreter.new()
	var content = _parse("( shuffle \n- { a } A\n -  { b } B\n)\nend\n")
	interpreter.init(content)

	var random_default_cycle = ["a", "b"]
	for _i in range(2):
		var rdc = interpreter.get_current_node().value
		assert_has(random_default_cycle, rdc)
		random_default_cycle.erase(rdc)

	assert_eq(random_default_cycle.size(), 0)
	# should re-shuffle after exausting all options
	random_default_cycle = ["a", "b"]
	for _i in range(2):
		var rdc = interpreter.get_current_node().value
		assert_has(random_default_cycle, rdc)
		random_default_cycle.erase(rdc)

	assert_eq(random_default_cycle.size(), 0)


func test_all_variations_not_available():
	var interpreter = ClydeInterpreter.new()
	var content = _parse("(\n - { a } A\n -  { b } B\n)\nend\n")
	interpreter.init(content)

	assert_eq_deep(interpreter.get_current_node().value, 'end')


func test_logic():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('logic')
	assert_eq_deep(ClydeParser.new().to_JSON_object(dialogue.get_content()).value, "variable was initialized with 1")
	assert_eq_deep(ClydeParser.new().to_JSON_object(dialogue.get_content()).value, "setting multiple variables")
	assert_eq_deep(ClydeParser.new().to_JSON_object(dialogue.get_content()).value, "4 == 4.  3 == 3")
	assert_eq_deep(ClydeParser.new().to_JSON_object(dialogue.get_content()).value, "This is a block")
	assert_eq_deep(ClydeParser.new().to_JSON_object(dialogue.get_content()).value, "inside a condition")
	var line = ClydeParser.new().to_JSON_object(dialogue.get_content())
	if(line.keys().size() == 0):
		assert_eq_deep(null, null)
	else:
		assert_eq_deep(line, null)


func test_variables():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('variables')
	var u = dialogue.get_content()
	assert_eq_deep(ClydeParser.new().to_JSON_object(u).value, "not")
	var t = dialogue.get_content()
	assert_eq_deep(ClydeParser.new().to_JSON_object(t).value, "equality")
	var p = dialogue.get_content()
	assert_eq_deep(ClydeParser.new().to_JSON_object(p).value, "alias equality")
	var y = dialogue.get_content()
	assert_eq_deep(ClydeParser.new().to_JSON_object(y).value, "trigger")
	var z = dialogue.get_content();
	assert_eq_deep(ClydeParser.new().to_JSON_object(z).value, "hey you")
	var q = dialogue.get_content()
	assert_eq_deep(ClydeParser.new().to_JSON_object(q).value, "hey {you}")
	var j = dialogue.get_content()


	dialogue.choose(1)

	var h = dialogue.get_content()
	var i = dialogue.get_content()
	var k = dialogue.get_content()
	assert_eq_deep(ClydeParser.new().to_JSON_object(h), _line({  "value": "I want to talk about the universe!", "speaker": "player" }))
	assert_eq_deep(ClydeParser.new().to_JSON_object(i), _line({  "value": "That's too complex!", "speaker": "npc" }))
	assert_eq_deep(ClydeParser.new().to_JSON_object(k), _line({  "value": "I'm in trouble" }))
	
	j.content[0].content = []
	j.content[1].content = []
	j.content[0].actions = []
	assert_eq_deep(
		ClydeParser.new().to_JSON_object(j),
		_options({ "content": [_action_content({ "mode": "once", "value": "Life" }), _option({ "mode": "once","value": "The universe" })] })
	)
	
	var line = ClydeParser.new().to_JSON_object(dialogue.get_content())
	
	if(line.keys().size() == 0):
		assert_eq_deep(null, null)
	else:
		assert_eq_deep(line, null)
	assert_eq_deep(dialogue.get_variable('xx'), true)


func test_set_variables():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('variables')
	dialogue.set_variable('first_time', true)
	assert_eq_deep(ClydeParser.new().to_JSON_object(dialogue.get_content()).value, "what do you want to talk about?")
	dialogue.set_variable('first_time', false)
	dialogue.start()
	assert_eq_deep(ClydeParser.new().to_JSON_object(dialogue.get_content()).value, "not")


func test_data_control():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('variations')

	assert_eq_deep(ClydeParser.new().to_JSON_object(dialogue.get_content()).value, "Hello")
	dialogue.start()
	assert_eq_deep(ClydeParser.new().to_JSON_object(dialogue.get_content()).value, "Hi")

	var dialogue2 = ClydeDialogue.new()
	dialogue2.load_dialogue('variations')
	dialogue2.load_data(dialogue.get_data())
	assert_eq_deep(dialogue2.get_content().value, "Hey")

	dialogue.clear_data()
	dialogue.start()
	assert_eq_deep(ClydeParser.new().to_JSON_object(dialogue.get_content()).value, "Hello")


func test_persisted_data_control_options():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('options')

	var content = _get_next_options_content(dialogue)
	assert_eq(content.content.size(), 3)

	dialogue.choose(0)
	dialogue.start()

	content = _get_next_options_content(dialogue)
	assert_eq(content.content.size(), 2)


	var stringified_data = JSON.stringify(
		{"access" : dialogue.get_data().access,
		"variables" : dialogue.get_data().variables,
		"internal" : dialogue.get_data().internal })

	var dialogue2 = ClydeDialogue.new()
	dialogue2.load_dialogue('options')
	dialogue2.load_data(dialogue.get_data())

	var content2 = _get_next_options_content(dialogue)
	assert_eq(content2.content.size(), 2)
	assert_eq_deep(content2, content)


func test_persisted_data_control_variations():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('variations')

	assert_eq_deep(ClydeParser.new().to_JSON_object(dialogue.get_content()).value, "Hello")
	dialogue.start()
	assert_eq_deep(ClydeParser.new().to_JSON_object(dialogue.get_content()).value, "Hi")

	var dialogue2 = ClydeDialogue.new()
	dialogue2.load_dialogue('variations')

	var memory = dialogue.get_data()

	dialogue2.load_data(memory)
	assert_eq_deep(dialogue2.get_content().value, "Hey")


var pending_events = []

func test_events():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('variables')
	dialogue.connect("event_triggered", Callable(self, "_on_event_triggered"))
	dialogue.connect("variable_changed", Callable(self, "_on_variable_changed"))

	pending_events.push_back({ "type": "variable", "name": "xx", "value": true })
	pending_events.push_back({ "type": "variable", "name": "first_time", "value": 2.0 })
	pending_events.push_back({ "type": "variable", "name": "a", "value": 3.0 })
	pending_events.push_back({ "type": "variable", "name": "b", "value": 3.0 })
	pending_events.push_back({ "type": "variable", "name": "c", "value": 3.0 })
	pending_events.push_back({ "type": "variable", "name": "d", "value": 3.0 })
	pending_events.push_back({ "type": "variable", "name": "a", "value": 6.0 })
	pending_events.push_back({ "type": "variable", "name": "a", "value": -10.0 })
	pending_events.push_back({ "type": "event", "name": "some_event" })
	pending_events.push_back({ "type": "event", "name": "another_event" })
	pending_events.push_back({ "type": "variable", "name": "a", "value": -14.0 })
	pending_events.push_back({ "type": "variable", "name": "b", "value": 1.0 })
	pending_events.push_back({ "type": "variable", "name": "c", "value": "hello" })
	pending_events.push_back({ "type": "variable", "name": "a", "value": 4.0 })
	pending_events.push_back({ "type": "variable", "name": "hp", "value": 5.0 })
	pending_events.push_back({ "type": "variable", "name": "s", "value": false })
	pending_events.push_back({ "type": "variable", "name": "x", "value": true })

	while true:
		var res = ClydeParser.new().to_JSON_object(dialogue.get_content())
		if res.size() == 0:
			break;
		if res.type == NodeFactory.NODE_TYPES.OPTIONS:
			dialogue.choose(0)

	assert_eq(pending_events.size(), 0)



func _on_variable_changed(name, value, _previous_value):
	for e in pending_events:
		if e.type == 'variable' and e.name == name and  typeof(e.value) == typeof(value) and  e.value == value:
			pending_events.erase(e)


func _on_event_triggered(event_name):
	for e in pending_events:
		if e.type == 'event' and e.name == event_name:
			pending_events.erase(e)


func test_file_path_without_extension():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('simple_lines')

	var lines = [
		_line({  "value": "Dinner at Jack Rabbit Slim's:" }),
		_line({  "value": "Don’t you hate that?", "speaker": "Mia" }),
		_line({  "value": "What?", "speaker": "Vincent" }),
		_line({  "value": "Uncomfortable silences. Why do we feel it’s necessary to yak about bullshit in order to be comfortable?", "speaker": "Mia", "id": "145" }),
		_line({  "value": "I don’t know. That’s a good question.", "speaker": "Vincent" }),
		_line({  "value": "That’s when you know you’ve found somebody special. When you can just shut the fuck up for a minute and comfortably enjoy the silence.", "speaker": "Mia", "id": "123"}),
	]

	for line in lines:
		assert_eq_deep(ClydeParser.new().to_JSON_object(dialogue.get_content()), line)


func test_uses_configured_dialogue_folder():
	var dialogue = ClydeDialogue.new()
	dialogue.dialogue_folder = 'res://dialogues'
	dialogue.load_dialogue('simple_lines')

	var lines = [
		_line({  "value": "Dinner at Jack Rabbit Slim's:" }),
		_line({  "value": "Don’t you hate that?", "speaker": "Mia" }),
		_line({  "value": "What?", "speaker": "Vincent" }),
		_line({  "value": "Uncomfortable silences. Why do we feel it’s necessary to yak about bullshit in order to be comfortable?", "speaker": "Mia", "id": "145" }),
		_line({  "value": "I don’t know. That’s a good question.", "speaker": "Vincent" }),
		_line({  "value": "That’s when you know you’ve found somebody special. When you can just shut the fuck up for a minute and comfortably enjoy the silence.", "speaker": "Mia", "id": "123"}),
	]

	for line in lines:
		assert_eq_deep(ClydeParser.new().to_JSON_object(dialogue.get_content()), line)


func test_dependent_logic():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('dependent_logic')
	var line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "variable was")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, " initialized with 1")
	assert_eq_deep(line_part.end_line, true)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "setting ")
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "multiple variables")
	assert_eq_deep(line_part.end_line, true)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "  4 == 4.  3 == 3")
	assert_eq_deep(line_part.end_line, true)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "you")
	assert_eq_deep(line_part.end_line, true)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "hey")
	assert_eq_deep(line_part.end_line, true)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "Hello ")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, " you!")
	assert_eq_deep(line_part.end_line, true)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, " This is a line inside a condition")
	assert_eq_deep(line_part.end_line, true)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "trigger ")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, " this!")
	assert_eq_deep(line_part.end_line, true)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "plz ")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, " trigger me daddy!!")
	assert_eq_deep(line_part.end_line, true)
	
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.value, "logic happening")
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	if(line_part.keys().size() == 0):
		assert_eq_deep(null, null)
	else:
		assert_eq_deep(line_part, null)
		

func test_bb_code():
	var dialogue = ClydeDialogue.new()
	dialogue.load_dialogue('bb_code')
	var line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "variable was")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, " initialized with 1")
	assert_eq_deep(line_part.part.bb_code_before_line, "[b]")
	assert_eq_deep(line_part.end_line, true)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "setting ")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "multiple ")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, " variables")
	assert_eq_deep(line_part.part.bb_code_before_line, "[b]")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "")
	assert_eq_deep(line_part.part.bb_code_before_line, "[/b]")
	assert_eq_deep(line_part.end_line, true)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "  4 == 4.  3 == 3")
	assert_eq_deep(line_part.end_line, true)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "you")
	assert_eq_deep(line_part.part.bb_code_before_line, "[b]")
	assert_eq_deep(line_part.end_line, true)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "hey")
	assert_eq_deep(line_part.end_line, true)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "Hello ")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, " you! ")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "")
	assert_eq_deep(line_part.part.bb_code_before_line, "[/b]")
	assert_eq_deep(line_part.end_line, true)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, " This is a ")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "line")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, " inside ")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "a ")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "condition")
	assert_eq_deep(line_part.end_line, true)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "")
	assert_eq_deep(line_part.part.bb_code_before_line, "[b]")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "")
	assert_eq_deep(line_part.part.bb_code_before_line, "[b]")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "")
	assert_eq_deep(line_part.part.bb_code_before_line, "[b]")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "")
	assert_eq_deep(line_part.part.bb_code_before_line, "[b]")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "")
	assert_eq_deep(line_part.part.bb_code_before_line, "[b]")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "")
	assert_eq_deep(line_part.part.bb_code_before_line, "[b]")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "")
	assert_eq_deep(line_part.part.bb_code_before_line, "[b]")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "")
	assert_eq_deep(line_part.part.bb_code_before_line, "[b]")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "")
	assert_eq_deep(line_part.part.bb_code_before_line, "[b]")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "")
	assert_eq_deep(line_part.part.bb_code_before_line, "[b]")
	assert_eq_deep(line_part.end_line, true)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "trigger")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "")
	assert_eq_deep(line_part.part.bb_code_before_line, "[b]")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, " this!")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "")
	assert_eq_deep(line_part.part.bb_code_before_line, "[b]")
	assert_eq_deep(line_part.end_line, true)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, "plz ")
	assert_eq_deep(line_part.end_line, false)
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.part.value, " trigger me daddy!!")
	assert_eq_deep(line_part.end_line, true)
	assert_eq_deep(line_part.part.bb_code_before_line, "[b]")
	
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	assert_eq_deep(line_part.value, "logic happening")
	line_part = ClydeParser.new().to_JSON_object(dialogue.get_content())
	if(line_part.keys().size() == 0):
		assert_eq_deep(null, null)
	else:
		assert_eq_deep(line_part, null)
