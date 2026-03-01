extends Node

var system_prompt:String ="""
Extract RTS game commands from user input into strictly formatted JSON. Do not output anything except the JSON.

# RULES
1. "aim": Must be an array of targets. Allowed values: ["first", "second", "third", "fourth"] OR specific surnames/names.
2. "orders": Must be an array of strings in "order:target" format. 
   - Allowed targets for build: house, foundry, stove. (e.g., "build:house")
   - Allowed targets for gather: rock, wood, food. (e.g., "gather:wood"). Map synonyms to these (e.g., "stone" -> "rock").
   - Targetless orders: "stop_fighting", "rest", "complimented", "dance".
   - Rename order: "rename:[NewName]" (e.g., "rename:Todd")
3. "order_sentiment": Must be exactly "positive" (contains please/polite), "negative" (urgent/aggressive/now), or "neutral".
4. CRITICAL: ONLY extract orders explicitly mentioned in the text. Do NOT hallucinate or add extra resources (e.g., do not add wood/food if only rock is mentioned).
5. If the input is unrecognizable or missing valid commands, output the Fallback JSON.

# FALLBACK JSON
{
  "aim": [],
  "orders": [],
  "order_sentiment": "neutral"
}

# EXAMPLES
Input: "Hey first and third fox, gather wood and build a stove please!"
Output: {"aim":["first", "third"],"orders":["gather:wood","build:stove"],"order_sentiment":"positive"}

Input: "Can the first and the second fox gather some stone?"
Output: {"aim":["first", "second"],"orders":["gather:rock"],"order_sentiment":"neutral"}

Input: "Smith, stop fighting right now!!"
Output: {"aim":["Smith"],"orders":["stop_fighting"],"order_sentiment":"negative"}

Input: "second, rest and then dance"
Output: {"aim":["second"],"orders":["rest","dance"],"order_sentiment":"neutral"}

Input: "blah blah blah"
Output: {"aim":[],"orders":[],"order_sentiment":"neutral"}

# CURRENT TASK
Input: 
"""

var mistral_realtime_client: MistralRealtime
var audio_capture: AudioCapture
var mistral_llm_client:MistralLlm

var _flush_timer: Timer = null

const order_number_character=70

var sentence_parsed:String = ""

var is_recording: bool = false
var llm_available: bool = true

var _api_key: String = EnvLoader.get_var("MISTRAL_API_KEY")

func _ready() -> void:
	
		# Create components
	mistral_realtime_client = MistralRealtime.new()
	audio_capture = AudioCapture.new()
	mistral_llm_client = MistralLlm.new()
	
	add_child(mistral_realtime_client)
	add_child(audio_capture)
	add_child(mistral_llm_client)
	
	mistral_realtime_client.tts_ready.connect(_on_tts_ready)
	mistral_llm_client.completion_received.connect(_on_llm_completion_received)
	mistral_llm_client.completion_error.connect(_on_llm_completion_error)
	
	# Create flush timer to periodically flush audio buffer
	_flush_timer = Timer.new()
	_flush_timer.wait_time = 600 # Flush every 1.5 seconds
	_flush_timer.timeout.connect(_on_flush_timer)
	audio_capture.audio_chunk_ready.connect(_on_audio_chunk_ready)
	add_child(_flush_timer)
	
	audio_capture.start_recording()
	mistral_realtime_client.connect_to_mistral(_api_key)
	
	if GuiManager != null:
		await GuiManager.ready
		GuiManager.gui_scene.talk_pressed.connect(_on_talk_start)
		GuiManager.gui_scene.talk_released.connect(_on_talk_stop)
	
func _on_audio_chunk_ready(audio_data: PackedByteArray) -> void:
	if is_recording:
		mistral_realtime_client.send_audio(audio_data)

func _on_flush_timer() -> void:
	if is_recording:
		print("Flushing audio buffer...")
		mistral_realtime_client.flush_audio()

func _on_talk_start() -> void:
	is_recording = true
	_flush_timer.start()
	print("Recording started")

func _on_talk_stop() -> void:
	is_recording = false
	_flush_timer.stop()
	mistral_realtime_client.flush_audio()
	print("Recording stopped")
	
	# Wait for LLM to be available
	while not llm_available:
		await get_tree().create_timer(0.1).timeout
	
	# Send chat completion with accumulated sentence
	if sentence_parsed.length() > 0:
		llm_available = false
		var messages = [
			{"role": "system", "content": system_prompt},
			{"role": "user", "content": sentence_parsed}
		]
		mistral_llm_client.send_chat_completion(messages, 0.7, 500, true)

func _on_tts_ready(tts_text:String):
	sentence_parsed += tts_text
	
	if sentence_parsed.length() > order_number_character:
		sentence_parsed = sentence_parsed.substr(sentence_parsed.length() - order_number_character)
	
	if GuiManager != null:
		GuiManager.change_caption(sentence_parsed)
	
func _on_llm_completion_received(response: Dictionary):
	var content=response["choices"][0]["message"]["content"]
	var parsed_response = _parse_json_response(content)
	print("Parsed response: ", parsed_response)
	
	if parsed_response["orders"].size() > 0:
		
		print("create order")
		var new_order = Order.new(parsed_response["aim"],parsed_response["orders"],parsed_response["order_sentiment"])
		
		if new_order != null:
			
			EntityManager.execute_order(new_order)
			sentence_parsed = ""
			if GuiManager != null:
				GuiManager.change_caption("")
	
	llm_available = true
	
func _on_llm_completion_error(error_message: String):
	print("LLM Error: ", error_message)
	llm_available = true 

func _parse_json_response(json_string: String) -> Dictionary:
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Failed to parse JSON response: ", json.get_error_message())
		return {}
	
	return json.get_data()
