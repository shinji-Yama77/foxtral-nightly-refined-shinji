extends Node
class_name AudioCapture


signal audio_chunk_ready(audio_data: PackedByteArray)

var audio_stream_player = null
var audio_effect_capture = null
var recording: bool = false
var chunk_size: int = 2048  # samples per chunk
var last_get: int = 0

func _ready() -> void:
	
	#Setup the audio stream and effect
	audio_stream_player = AudioStreamPlayer.new()
	add_child(audio_stream_player)
	
	var bus_idx = AudioServer.get_bus_index("Record")
	
	if bus_idx == -1:
		# Create Record bus if it doesn't exist
		bus_idx = AudioServer.bus_count
		AudioServer.add_bus(bus_idx)
		AudioServer.set_bus_name(bus_idx, "Record")
	
	# Set bus volume to ensure we capture audio
	AudioServer.set_bus_volume_db(bus_idx, 0.0)  # 0 dB = full volume
	
	# Default: Don't send to Master (no monitoring)
	# Call enable_monitoring(true) to hear microphone through speakers
	AudioServer.set_bus_send(bus_idx, "")
	
	# Set player to use Record bus
	audio_stream_player.bus = "Record"
	
	# Add AudioEffectCapture if not present
	var has_capture = false
	for i in AudioServer.get_bus_effect_count(bus_idx):
		var effect = AudioServer.get_bus_effect(bus_idx, i)
		if effect is AudioEffectCapture:
			audio_effect_capture = effect
			has_capture = true
			break
	
	if not has_capture:
		audio_effect_capture = AudioEffectCapture.new()

		audio_effect_capture.buffer_length = 1  # 1 second buffer
		AudioServer.add_bus_effect(bus_idx, audio_effect_capture)
	
	print("Audio capture setup complete (bus volume: ", AudioServer.get_bus_volume_db(bus_idx), " dB)")

## Start recording from microphone
func start_recording(device_name: String = "Default") -> bool:
	if recording:
		return false
	
	print("Starting microphone capture...")
	
	# Set microphone input device
	var devices = AudioServer.get_input_device_list()
	print("Available devices: ", devices)
	
	if device_name != "Default" and device_name in devices:
		AudioServer.input_device = device_name
		print("Using device: ", device_name)
	else:
		print("Using default device")
	
	# Create microphone stream
	var mic_stream = AudioStreamMicrophone.new()
	audio_stream_player.stream = mic_stream
	audio_stream_player.volume_db = 0.0  # Ensure full volume
	audio_stream_player.play()
	
	print("AudioStreamPlayer volume: ", audio_stream_player.volume_db, " dB")
	
	# Enable microphone capture on the Record bus
	var bus_idx = AudioServer.get_bus_index("Record")
	AudioServer.set_bus_mute(bus_idx, false)
	AudioServer.set_bus_volume_db(bus_idx, 0.0)
	
	print("Record bus volume: ", AudioServer.get_bus_volume_db(bus_idx), " dB")
	print("Record bus muted: ", AudioServer.is_bus_mute(bus_idx))
	
	recording = true
	set_process(true)
	
	print("Microphone recording started")
	return true
	
func stop_recording() -> void:
	recording = false
	set_process(false)
	
	if audio_stream_player:
		audio_stream_player.stop()
	
	if audio_effect_capture:
		audio_effect_capture.clear_buffer()
	
	print("Microphone recording stopped")
	
func _process(_delta):
	if not recording or not audio_effect_capture:
		return
	
	# Check if we have enough frames
	var frames_available = audio_effect_capture.get_frames_available()
	if frames_available >= chunk_size:
		process_audio_chunk()

func process_audio_chunk() -> void:
	
	var buffer_ms = Time.get_ticks_msec()-last_get
	var audio_frames = audio_effect_capture.get_buffer(chunk_size)
	last_get = Time.get_ticks_msec()
	
	var length = audio_frames.size()
	
	#print("audio lenght ",length/buffer_ms*1000)
	
	if audio_frames.size() == 0:
		return
	
	# Convert stereo float32 to mono PCM16
	var max =0
	
	for i in audio_frames.size():
		
		if audio_frames[i].x > max:
			max =  audio_frames[i].x
	
	var pcm16_data = convert_to_pcm16(audio_frames)
	audio_chunk_ready.emit(pcm16_data)

func convert_to_pcm16(frames:PackedVector2Array) -> PackedByteArray:
		
	var byte_array = PackedByteArray()
	byte_array.resize(frames.size() * 2)  # 2 bytes per sample (16-bit)
	
	for i in frames.size():
		
		var sample = (frames[i].x) 
		
		var pcm16_value =  int(0x7fff * sample)
		
		byte_array.encode_s16(i * 2, pcm16_value)
		
	return byte_array
		
