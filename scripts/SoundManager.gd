extends Node

# Enhanced Sound & Music Manager for Basketball Bounceback
# Integrates authentic audio assets with procedural synthesis

var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var sounds: Dictionary = {}
var is_muted: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(8):
		var p = AudioStreamPlayer.new()
		add_child(p)
		sfx_players.append(p)
	
	music_player = AudioStreamPlayer.new()
	music_player.finished.connect(play_music)
	add_child(music_player)
	
	_load_audio_assets()
	play_music()

func _load_audio_assets() -> void:
	# Load sound effects from assets/sounds if available
	_try_load_sfx("star", "res://assets/sounds/coin.wav")
	_try_load_sfx("jump", "res://assets/sounds/jump.wav")
	_try_load_sfx("slam", "res://assets/sounds/explosion.wav")
	_try_load_sfx("hit", "res://assets/sounds/hurt.wav")
	_try_load_sfx("spring", "res://assets/sounds/power_up.wav")
	_try_load_sfx("rim", "res://assets/sounds/tap.wav")
	_try_load_sfx("stomp", "res://assets/sounds/tap.wav")

	# Synthesize complementary sounds for basketball
	if not sounds.has("bounce"):
		sounds["bounce"] = _synth_bounce()
	if not sounds.has("swish"):
		sounds["swish"] = _synth_swish()
	if not sounds.has("cheer"):
		sounds["cheer"] = _synth_cheer()
	if not sounds.has("buzzer"):
		sounds["buzzer"] = _synth_buzzer()

	# Load background music
	var music_res = load("res://assets/music/time_for_adventure.mp3")
	if music_res:
		music_player.stream = music_res
		music_player.volume_db = -12.0

func _try_load_sfx(sound_name: String, path: String) -> void:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res:
			sounds[sound_name] = res
			return
	# Fallback synth if file not loaded
	if sound_name == "bounce": sounds["bounce"] = _synth_bounce()
	elif sound_name == "jump": sounds["jump"] = _synth_jump()
	elif sound_name == "slam": sounds["slam"] = _synth_slam()
	elif sound_name == "spring": sounds["spring"] = _synth_spring()
	elif sound_name == "star": sounds["star"] = _synth_star()
	elif sound_name == "stomp": sounds["stomp"] = _synth_stomp()
	elif sound_name == "rim": sounds["rim"] = _synth_rim()
	elif sound_name == "hit": sounds["hit"] = _synth_hit()

func play_music() -> void:
	if not is_muted and music_player and music_player.stream and not music_player.playing:
		music_player.play()

func stop_music() -> void:
	if music_player:
		music_player.stop()

func play(sfx_name: String, volume_scale: float = 1.0) -> void:
	if is_muted or not sounds.has(sfx_name):
		return
	for p in sfx_players:
		if not p.playing:
			p.stream = sounds[sfx_name]
			p.volume_db = linear_to_db(clampf(volume_scale, 0.1, 2.0))
			p.play()
			return
	sfx_players[0].stream = sounds[sfx_name]
	sfx_players[0].volume_db = linear_to_db(clampf(volume_scale, 0.1, 2.0))
	sfx_players[0].play()

func toggle_mute() -> bool:
	is_muted = !is_muted
	if is_muted:
		stop_music()
	else:
		play_music()
	return is_muted

# --- Synthesizers for unique basketball audio ---
func _create_wav(byte_data: PackedByteArray, s_rate: int = 22050) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = s_rate
	wav.stereo = false
	wav.data = byte_data
	return wav

func _synth_bounce() -> AudioStreamWAV:
	# Silent bounce - no "dap dap" sound
	var s_rate = 22050
	var duration = 0.12
	var total_samples = int(s_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	# Fill with silence (128 = mute for 8-bit unsigned WAV)
	for i in range(total_samples):
		bytes[i] = 128
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = s_rate
	wav.stereo = false
	wav.data = bytes
	return wav

func _synth_jump() -> AudioStreamWAV:
	var duration = 0.18
	var s_rate = 22050
	var total_samples = int(s_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	var phase: float = 0.0
	for i in range(total_samples):
		var t = float(i) / s_rate
		var frac = t / duration
		var freq = lerpf(180.0, 480.0, frac)
		phase += freq * (TAU / s_rate)
		var env = sin(frac * PI) * (1.0 - frac * 0.3)
		var sample = sin(phase) * env
		bytes[i] = int(clampf((sample * 0.65 + 1.0) * 127.5, 0, 255))
	return _create_wav(bytes, s_rate)

func _synth_slam() -> AudioStreamWAV:
	var duration = 0.22
	var s_rate = 22050
	var total_samples = int(s_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	var phase: float = 0.0
	for i in range(total_samples):
		var t = float(i) / s_rate
		var frac = t / duration
		var freq = lerpf(240.0, 45.0, pow(frac, 0.6))
		phase += freq * (TAU / s_rate)
		var env = pow(1.0 - frac, 1.5)
		var noise = (randf() * 2.0 - 1.0) * 0.25 * env
		var sample = (sin(phase) * 0.75 + noise) * env
		bytes[i] = int(clampf((sample * 0.8 + 1.0) * 127.5, 0, 255))
	return _create_wav(bytes, s_rate)

func _synth_spring() -> AudioStreamWAV:
	var duration = 0.3
	var s_rate = 22050
	var total_samples = int(s_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	var phase: float = 0.0
	for i in range(total_samples):
		var t = float(i) / s_rate
		var frac = t / duration
		var freq = 220.0 + sin(t * 40.0) * 80.0 + frac * 280.0
		phase += freq * (TAU / s_rate)
		var env = (1.0 - frac)
		var sample = sin(phase) * env
		bytes[i] = int(clampf((sample * 0.65 + 1.0) * 127.5, 0, 255))
	return _create_wav(bytes, s_rate)

func _synth_star() -> AudioStreamWAV:
	var duration = 0.22
	var s_rate = 22050
	var total_samples = int(s_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	var p1: float = 0.0
	var p2: float = 0.0
	for i in range(total_samples):
		var t = float(i) / s_rate
		var frac = t / duration
		p1 += 660.0 * (TAU / s_rate)
		p2 += 1100.0 * (TAU / s_rate)
		var env = pow(1.0 - frac, 1.4)
		var sample = (sin(p1) * 0.5 + sin(p2) * 0.5) * env
		bytes[i] = int(clampf((sample * 0.6 + 1.0) * 127.5, 0, 255))
	return _create_wav(bytes, s_rate)

func _synth_stomp() -> AudioStreamWAV:
	var duration = 0.15
	var s_rate = 22050
	var total_samples = int(s_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	var phase: float = 0.0
	for i in range(total_samples):
		var t = float(i) / s_rate
		var frac = t / duration
		var freq = lerpf(300.0, 70.0, frac)
		phase += freq * (TAU / s_rate)
		var noise = (randf() * 2.0 - 1.0) * 0.4
		var env = pow(1.0 - frac, 2.0)
		var sample = (sin(phase) * 0.6 + noise) * env
		bytes[i] = int(clampf((sample * 0.8 + 1.0) * 127.5, 0, 255))
	return _create_wav(bytes, s_rate)

func _synth_rim() -> AudioStreamWAV:
	var duration = 0.16
	var s_rate = 22050
	var total_samples = int(s_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	var p1: float = 0.0
	var p2: float = 0.0
	for i in range(total_samples):
		var t = float(i) / s_rate
		var frac = t / duration
		p1 += 940.0 * (TAU / s_rate)
		p2 += 1420.0 * (TAU / s_rate)
		var env = pow(1.0 - frac, 2.5)
		var sample = (sin(p1) * 0.6 + sin(p2) * 0.4) * env
		bytes[i] = int(clampf((sample * 0.7 + 1.0) * 127.5, 0, 255))
	return _create_wav(bytes, s_rate)

func _synth_swish() -> AudioStreamWAV:
	var duration = 0.28
	var s_rate = 22050
	var total_samples = int(s_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	for i in range(total_samples):
		var t = float(i) / s_rate
		var frac = t / duration
		var env = sin(frac * PI) * pow(1.0 - frac, 0.8)
		var noise = (randf() * 2.0 - 1.0) * env
		bytes[i] = int(clampf((noise * 0.5 + 1.0) * 127.5, 0, 255))
	return _create_wav(bytes, s_rate)

func _synth_cheer() -> AudioStreamWAV:
	var duration = 0.85
	var s_rate = 22050
	var total_samples = int(s_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	var filter_val = 0.0
	for i in range(total_samples):
		var t = float(i) / s_rate
		var frac = t / duration
		var env = sin(frac * PI)
		var white = randf() * 2.0 - 1.0
		filter_val = filter_val * 0.9 + white * 0.1
		var sample = filter_val * env * 1.8
		bytes[i] = int(clampf((sample * 0.7 + 1.0) * 127.5, 0, 255))
	return _create_wav(bytes, s_rate)

func _synth_buzzer() -> AudioStreamWAV:
	var duration = 0.7
	var s_rate = 22050
	var total_samples = int(s_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	var phase: float = 0.0
	for i in range(total_samples):
		var t = float(i) / s_rate
		var frac = t / duration
		phase += 140.0 * (TAU / s_rate)
		var sq = 1.0 if sin(phase) > 0.0 else -1.0
		var env = 1.0 if frac < 0.85 else (1.0 - (frac - 0.85) / 0.15)
		var sample = sq * env
		bytes[i] = int(clampf((sample * 0.5 + 1.0) * 127.5, 0, 255))
	return _create_wav(bytes, s_rate)

func _synth_hit() -> AudioStreamWAV:
	var duration = 0.2
	var s_rate = 22050
	var total_samples = int(s_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(total_samples)
	var phase: float = 0.0
	for i in range(total_samples):
		var t = float(i) / s_rate
		var frac = t / duration
		var freq = lerpf(380.0, 50.0, frac)
		phase += freq * (TAU / s_rate)
		var noise = (randf() * 2.0 - 1.0) * 0.3
		var env = pow(1.0 - frac, 1.8)
		var sample = (sin(phase) * 0.7 + noise) * env
		bytes[i] = int(clampf((sample * 0.75 + 1.0) * 127.5, 0, 255))
	return _create_wav(bytes, s_rate)
