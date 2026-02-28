extends Node
class_name MistralLlm
# OpenAI API Configuration
var api_key: String = EnvLoader.get_var("MISTRAL_API_KEY")
var model: String = "ministral-14b-2512"
var api_url: String = "https://api.mistral.ai/v1/chat/completions"

var http_request: HTTPRequest
var affinity_uid: String = ""

signal completion_received(response: Dictionary)
signal completion_error(error_message: String)

func _ready() -> void:
	# Load API key from .env if not set
	
	# Generate random UID for x-affinity factor
	affinity_uid = _generate_uid()
	
	# Setup HTTP request node
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	print("LLM Manager initialized with affinity UID: ", affinity_uid)

func _generate_uid() -> String:
	var uid = ""
	var chars = "0123456789abcdef"
	for i in range(32):
		uid += chars[randi() % chars.length()]
		if i in [7, 11, 15, 19]:
			uid += "-"
	return uid

func send_chat_completion(messages: Array, temperature: float = 0.01, max_tokens: int = 500, force_json: bool = false) -> void:
	if api_key.is_empty():
		emit_signal("completion_error", "API key is not set")
		return
	
	var request_body = {
		"model": model,
		"messages": messages,
		"temperature": temperature,
		"max_tokens": max_tokens
	}
	
	# Force JSON structured output
	if force_json:
		request_body["response_format"] = {"type": "json_object"}
	
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key,
		"x-affinity-factor: " + affinity_uid
	]
	
	var json_body = JSON.stringify(request_body)
	var error = http_request.request(api_url, headers, HTTPClient.METHOD_POST, json_body)
	

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		emit_signal("completion_error", "Request failed with result: " + str(result))
		return
	
	if response_code != 200:
		emit_signal("completion_error", "HTTP error: " + str(response_code))
		return
	
	var json_string = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		emit_signal("completion_error", "Failed to parse JSON response")
		return
	
	var response_data = json.get_data()
	
	if response_data.has("error"):
		emit_signal("completion_error", "API error: " + str(response_data["error"]))
		return
	
	emit_signal("completion_received", response_data)

func parse_completion_response(response: Dictionary) -> String:
	if response.has("choices") and response["choices"].size() > 0:
		var choice = response["choices"][0]
		if choice.has("message") and choice["message"].has("content"):
			return choice["message"]["content"]
	return ""
