extends Node

var system_prompt:String ="""
You are the expert RTS order formatter from a tiny city builder where user control fox. You will receive instruction from user and need to parse them down to JSON.
the list of possible aim are :
- first, second, third, fourth, or any surname
the list of possible order are : 
- build [house, foundry, stove]
- gather [rock, wood, food] Can't have amount
- stop_fighting
- rest
- complimented 
- dance
- rename (new name)
Directly answer with a JSON formatted like this :
{
	"aim":list of aim,
	"orders":list of order in the format of "order:target" for example ["build:house","gather:wood","gather:food"]
	"order_sentiment": "positive", "negative" or "neutral" following the tone of the order (for example "gather 10 wood" is neutral, "gather 10 wood now" is negative and "gather 10 wood please" is positive
}
if the instruction is not clear enough to parse any of the above, answer with an empty JSON like this :
{
	"aim":[],
	"orders":[],
	"order_sentiment":"neutral"
}
JSON
"""

var mistral_realtime_client: MistralRealtime
var audio_capture: AudioCapture
var mistral_llm_client:MistralLlm

var _flush_timer: Timer = null

var _api_key: String = "MoEMaEZrUWjBNdsmQoyTigL9ylcy5Y9X"

var sentence_parsed:String = ""

var llm_available = true

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
	_flush_timer.autostart=true
	_flush_timer.timeout.connect(_on_flush_timer)
	audio_capture.audio_chunk_ready.connect(_on_audio_chunk_ready)
	add_child(_flush_timer)
	
	audio_capture.start_recording()
	mistral_realtime_client.connect_to_mistral(_api_key)

func _on_audio_chunk_ready(audio_data: PackedByteArray):
	
	mistral_realtime_client.send_audio(audio_data)

func _on_flush_timer():
	# Periodically flush audio to trigger transcription
	print("Flushing audio buffer...")
	mistral_realtime_client.flush_audio()

func _on_tts_ready(tts_text:String):
	
	sentence_parsed+=tts_text
	
	print(sentence_parsed)
	
	if llm_available:
		
		var messages = [
			{"role": "system", "content": system_prompt},
			{"role": "user", "content": sentence_parsed}
		]

		mistral_llm_client.send_chat_completion(messages, 0.7, 500, true)
	
func _on_llm_completion_received(response: Dictionary) -> void:
	llm_available = true
	
	if not response.has("choices") or response["choices"].size() == 0 or \
	   not response["choices"][0].has("message") or not response["choices"][0]["message"].has("content"):
		print("Invalid LLM response")
		return
	
	var parsed := _parse_and_validate_json(response["choices"][0]["message"]["content"])
	print("Parsed response: ", parsed)
	
	if parsed["orders"].size() > 0:
		EntityManager.execute_order(Order.new(parsed["aim"], parsed["orders"], parsed["order_sentiment"]))
		sentence_parsed = ""
	
func _on_llm_completion_error(error_message: String) -> void:
	print("LLM Error: ", error_message)
	llm_available = true

func _parse_and_validate_json(json_string: String) -> Dictionary:
	var default := {"aim": [], "orders": [], "order_sentiment": "neutral"}
	var json := JSON.new()
	
	if json.parse(json_string) != OK or typeof(json.get_data()) != TYPE_DICTIONARY:
		print("Invalid JSON: ", json.get_error_message() if json.parse(json_string) != OK else "Not a dictionary")
		return default
	
	var data := json.get_data() as Dictionary
	return {
		"aim": data.get("aim", []) if typeof(data.get("aim")) == TYPE_ARRAY else [],
		"orders": data.get("orders", []).filter(func(o): return typeof(o) == TYPE_STRING and ":" in o) if typeof(data.get("orders")) == TYPE_ARRAY else [],
		"order_sentiment": data.get("order_sentiment", "neutral") if data.get("order_sentiment", "").to_lower() in ["positive", "negative", "neutral"] else "neutral"
	}
