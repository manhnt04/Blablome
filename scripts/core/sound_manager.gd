class_name SoundManagerClass
extends Node

## Procedural Sound FX Engine & Audio Manager
## Generates responsive, punchy retro audio feedback in-engine

var _audio_players: Array[AudioStreamPlayer] = []
var _cached_streams: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Pre-allocate audio voice pool
	for i in range(8):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_audio_players.append(p)
		
	_generate_all_sounds()

func _play_stream(stream: AudioStream, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	for p in _audio_players:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch_scale
			p.volume_db = volume_db
			p.play()
			return
	# Steal first player if all busy
	_audio_players[0].stream = stream
	_audio_players[0].pitch_scale = pitch_scale
	_audio_players[0].volume_db = volume_db
	_audio_players[0].play()

func play_card_click() -> void:
	_play_stream(_cached_streams.get("click"), randf_range(0.95, 1.05), -4.0)

func play_card_deal() -> void:
	_play_stream(_cached_streams.get("deal"), randf_range(0.9, 1.1), -6.0)

func play_score_chip() -> void:
	_play_stream(_cached_streams.get("chip"), randf_range(0.98, 1.15), -3.0)

func play_mult_punch() -> void:
	_play_stream(_cached_streams.get("mult"), randf_range(0.95, 1.05), 0.0)

func play_cash_register() -> void:
	_play_stream(_cached_streams.get("cash"), 1.0, -2.0)

func play_victory() -> void:
	_play_stream(_cached_streams.get("victory"), 1.0, 2.0)

func play_defeat() -> void:
	_play_stream(_cached_streams.get("defeat"), 1.0, 2.0)

func _generate_all_sounds() -> void:
	_cached_streams["click"] = _make_tone(1100.0, 0.035, "sine", 0.8)
	_cached_streams["deal"] = _make_noise(0.06, 0.4)
	_cached_streams["chip"] = _make_tone(880.0, 0.05, "sine", 0.6)
	_cached_streams["mult"] = _make_tone(180.0, 0.14, "saw", 0.9)
	_cached_streams["cash"] = _make_dual_chime(1760.0, 2637.0, 0.28)
	_cached_streams["victory"] = _make_fanfare(0.45)
	_cached_streams["defeat"] = _make_tone_slide(180.0, 50.0, 0.45)

func _make_tone(freq: float, duration: float, type: String = "sine", decay: float = 1.0) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(duration * sample_rate)
	var byte_data = PackedByteArray()
	byte_data.resize(num_samples * 2) # 16-bit mono
	
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var env = exp(-decay * (float(i) / float(num_samples)) * 5.0)
		var val = 0.0
		if type == "sine":
			val = sin(t * freq * TAU)
		elif type == "saw":
			val = fmod(t * freq, 1.0) * 2.0 - 1.0
			
		var sample_val = int(clamp(val * env * 24000.0, -32767.0, 32767.0))
		byte_data.encode_s16(i * 2, sample_val)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_data
	return stream

func _make_tone_slide(freq_start: float, freq_end: float, duration: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(duration * sample_rate)
	var byte_data = PackedByteArray()
	byte_data.resize(num_samples * 2)
	
	var phase: float = 0.0
	for i in range(num_samples):
		var progress = float(i) / float(num_samples)
		var freq = lerp(freq_start, freq_end, progress)
		phase += (freq / sample_rate) * TAU
		var env = 1.0 - progress
		var val = sin(phase) * env
		var sample_val = int(clamp(val * 26000.0, -32767.0, 32767.0))
		byte_data.encode_s16(i * 2, sample_val)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_data
	return stream

func _make_noise(duration: float, decay: float = 1.0) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(duration * sample_rate)
	var byte_data = PackedByteArray()
	byte_data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var env = exp(-decay * (float(i) / float(num_samples)) * 4.0)
		var val = randf_range(-1.0, 1.0)
		var sample_val = int(clamp(val * env * 18000.0, -32767.0, 32767.0))
		byte_data.encode_s16(i * 2, sample_val)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_data
	return stream

func _make_dual_chime(f1: float, f2: float, duration: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(duration * sample_rate)
	var byte_data = PackedByteArray()
	byte_data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var env = exp(-(float(i) / float(num_samples)) * 4.5)
		var val = (sin(t * f1 * TAU) * 0.5 + sin(t * f2 * TAU) * 0.5) * env
		var sample_val = int(clamp(val * 26000.0, -32767.0, 32767.0))
		byte_data.encode_s16(i * 2, sample_val)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_data
	return stream

func _make_fanfare(duration: float) -> AudioStreamWAV:
	var sample_rate: int = 22050
	var num_samples: int = int(duration * sample_rate)
	var byte_data = PackedByteArray()
	byte_data.resize(num_samples * 2)
	
	var freqs = [523.25, 659.25, 783.99, 1046.50] # C5, E5, G5, C6
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var note_idx = mini(int(t / (duration / 4.0)), 3)
		var f = freqs[note_idx]
		var val = sin(t * f * TAU) * 0.8
		var sample_val = int(clamp(val * 24000.0, -32767.0, 32767.0))
		byte_data.encode_s16(i * 2, sample_val)
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_data
	return stream
