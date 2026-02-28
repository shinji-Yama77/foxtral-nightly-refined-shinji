extends Node
class_name MistralRealtime

const BASE_URL = "wss://api.mistral.ai/v1/audio/transcriptions/realtime"

var _ws: WebSocketPeer = null

var _model: String = "voxtral-mini-transcribe-realtime-2602"
var _audio_format: String = "pcm16le" 
var _sample_rate: int = 48000
var _connected: bool = false
var _audio_chunks_sent = 0

signal tts_ready(tts_text:String)

func _ready():
	set_process(true)
	
func _process(_delta):
	if _ws:
		_ws.poll()
		var state = _ws.get_ready_state()
		
		
		if state == WebSocketPeer.STATE_CONNECTING:
			# Still connecting, wait...
			pass
		
		elif state == WebSocketPeer.STATE_OPEN:
			
			if _connected == false:
			
				change_settings(
					{
						"audio_format": {
							"encoding": "pcm_s16le",
							"sample_rate": _sample_rate
						},
						"target_streaming_delay_ms":500
					}
				)
				_connected = true
				print("Stream setup")
			var packet_count = _ws.get_available_packet_count()
			
			if packet_count > 0:
				print(">>> ", packet_count, " packet(s) available!")
			
			while _ws.get_available_packet_count() > 0:
				var packet = _ws.get_packet()
				var text = packet.get_string_from_utf8()
				#print("Received raw packet: ", text.substr(0, 200) if text.length() > 200 else text)
				
				var payload = JSON.parse_string(text)
				
				if payload["type"]=="transcription.text.delta":
					
					tts_ready.emit(payload["text"])
				
				
				
		elif state == WebSocketPeer.STATE_CLOSING:
			print("WebSocket closing...")
		
		elif state == WebSocketPeer.STATE_CLOSED:
			var close_code = _ws.get_close_code()
			var close_reason = _ws.get_close_reason()
			print("WebSocket closed. Code: ", close_code, " Reason: ", close_reason)
			
			if _connected:
				_connected = false
				print("Connection closed: %s (code %d)" % [close_reason, close_code])
			_ws = null

## Connect to Mistral realtime API
func connect_to_mistral(api_key: String) -> bool:
	
	# Debug: Check if API key is loaded
	if api_key.is_empty():
		print("Missing API key")
		return false
	
	print("Connecting with API key: ", api_key.substr(0, 8) + "...")
	
	var url = "%s?model=%s" % [BASE_URL, _model]
	
	_ws = WebSocketPeer.new()
	
	# Set headers for authentication
	var headers = PackedStringArray([
		"Authorization: Bearer %s" % api_key,
	])
	_ws.handshake_headers = headers
	
	print("Connecting to: ", url)
	
	# Connect with TLS options (default secure connection)
	var err = _ws.connect_to_url(url)
	if err != OK:
		print("Failed to connect: %d" % err)
		return false
	print("WebSocket connection initiated, waiting for handshake...")
	return true
	
func change_settings(settings:Dictionary) -> void:
	
	var message ={
		"type": "session.update",
		"session": settings
	}
	
	_send_json(message)
	
## Send audio chunk (PCM16 format)
func send_audio(audio_data: PackedByteArray) -> void:
	if not _connected:
		print("WARNING: Cannot send audio - not connected")
		return
	
	var base64_audio = Marshalls.raw_to_base64(audio_data)
	var message = {
		"type": "input_audio.append",
		"audio": base64_audio
	}
	_send_json(message)
	
	_audio_chunks_sent += 1
	
## Flush audio buffer (forces processing of buffered audio)
func flush_audio() -> void:
	if not _connected:
		print("WARNING: Cannot flush - not connected")
		return
	
	print(">>> Sending flush command to server...")
	var message = {"type": "input_audio.flush"}
	_send_json(message)

## End audio input
func end_audio() -> void:
	if not _connected:
		return
	
	var message = {"type": "input_audio.end"}
	_send_json(message)
	
func _send_json(data: Dictionary) -> void:
	if not _ws:
		print("ERROR: WebSocket is null")
		return
	
	var json = JSON.stringify(data)
	var err = _ws.send_text(json)
	
	if err != OK:
		print("ERROR: Failed to send WebSocket message: ", err)
	else:
		# Only log non-audio messages to avoid spam
		if data.get("type") != "input_audio.append":
			print("Sent message: ", data.get("type"))
