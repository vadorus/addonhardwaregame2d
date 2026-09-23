extends Node

var _ambient_player: AudioStreamPlayer
var _ui_player: AudioStreamPlayer
var _ambient_stream: AudioStreamWAV
var _ambient_enabled := false

func _ready() -> void:
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "AmbientPlayer"
	add_child(_ambient_player)

	_ui_player = AudioStreamPlayer.new()
	_ui_player.name = "UiSfxPlayer"
	add_child(_ui_player)

	_ambient_stream = _build_garage_ambience()
	_ambient_player.stream = _ambient_stream
	_apply_volumes()
	SettingsManager.settings_changed.connect(_on_settings_changed)

func _on_settings_changed(section, _key, _value) -> void:
	if str(section) in ["audio", "*"]:
		_apply_volumes()

func _apply_volumes() -> void:
	if _ambient_player == null or _ui_player == null:
		return
	var master := clampf(float(SettingsManager.get_setting("audio", "master_volume")), 0.0, 1.0)
	var ambience := clampf(float(SettingsManager.get_setting("audio", "music_volume")), 0.0, 1.0)
	var sfx := clampf(float(SettingsManager.get_setting("audio", "sfx_volume")), 0.0, 1.0)
	_ambient_player.volume_db = _linear_volume_db(master * ambience * 0.42)
	_ui_player.volume_db = _linear_volume_db(master * sfx * 0.72)
	if master <= 0.001 or ambience <= 0.001:
		if _ambient_player.playing:
			_ambient_player.stop()
	elif _ambient_enabled and not _ambient_player.playing:
		_ambient_player.play()

func _linear_volume_db(value: float) -> float:
	if value <= 0.001:
		return -80.0
	return linear_to_db(value)

func set_garage_ambience_enabled(enabled: bool) -> void:
	_ambient_enabled = enabled
	if _ambient_player == null:
		return
	_apply_volumes()
	if not enabled and _ambient_player.playing:
		_ambient_player.stop()
	elif enabled and not _ambient_player.playing:
		var master := float(SettingsManager.get_setting("audio", "master_volume"))
		var ambience := float(SettingsManager.get_setting("audio", "music_volume"))
		if master > 0.001 and ambience > 0.001:
			_ambient_player.play()

func play_ui(event_name: String) -> void:
	if _ui_player == null:
		return
	var stream := _build_event_stream(event_name)
	if stream == null:
		return
	_ui_player.stream = stream
	_ui_player.play()

func _build_event_stream(event_name: String) -> AudioStreamWAV:
	var frequencies: Array[float] = []
	var duration := 0.18
	match event_name:
		"accept":
			frequencies = [420.0, 560.0]
			duration = 0.20
		"success":
			frequencies = [520.0, 660.0, 820.0]
			duration = 0.34
		"unlock":
			frequencies = [430.0, 640.0, 860.0]
			duration = 0.36
		"decision":
			frequencies = [360.0, 470.0]
			duration = 0.22
		"bug":
			frequencies = [240.0, 185.0]
			duration = 0.20
		"tick":
			frequencies = [650.0]
			duration = 0.07
		_:
			frequencies = [500.0]
			duration = 0.12
	return _build_tone_sequence(frequencies, duration)

func _build_tone_sequence(frequencies: Array[float], duration: float) -> AudioStreamWAV:
	var rate := 22050
	var sample_count := maxi(int(float(rate) * duration), 1)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var count := maxi(frequencies.size(), 1)
	for i in range(sample_count):
		var t := float(i) / float(rate)
		var ratio := float(i) / float(sample_count)
		var note_index := mini(int(ratio * float(count)), count - 1)
		var freq := frequencies[note_index] if not frequencies.is_empty() else 500.0
		var attack := clampf(ratio / 0.08, 0.0, 1.0)
		var release := clampf((1.0 - ratio) / 0.18, 0.0, 1.0)
		var envelope := minf(attack, release)
		var sample_float := sin(TAU * freq * t) * 0.25 * envelope
		var sample := clampi(int(round(sample_float * 32767.0)), -32768, 32767)
		data.encode_s16(i * 2, sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav

func _build_garage_ambience() -> AudioStreamWAV:
	var rate := 22050
	var duration := 4.0
	var sample_count := int(float(rate) * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / float(rate)
		var mains := sin(TAU * 50.0 * t) * 0.030
		var fan := sin(TAU * 43.0 * t) * 0.018
		var harmonic := sin(TAU * 100.0 * t) * 0.010
		var pseudo_noise := sin(t * 2173.0) * sin(t * 731.0) * 0.012
		var slow_variation := 0.82 + 0.18 * sin(TAU * 0.17 * t)
		var sample_float := (mains + fan + harmonic + pseudo_noise) * slow_variation
		var sample := clampi(int(round(sample_float * 32767.0)), -32768, 32767)
		data.encode_s16(i * 2, sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	# Keep the inclusive mixer boundary inside the PCM buffer.
	wav.loop_end = sample_count - 1
	return wav
