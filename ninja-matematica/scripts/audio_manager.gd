extends Node

const SETTINGS_PATH := "user://ninja_matematica.cfg"
const SAMPLE_RATE := 22050

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var music_enabled := true
var sfx_enabled := true
var smash_stream: AudioStreamWAV
var mistake_stream: AudioStreamWAV
var ui_stream: AudioStreamWAV


func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.volume_db = -23.0
	add_child(music_player)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SfxPlayer"
	sfx_player.volume_db = -7.0
	add_child(sfx_player)
	music_player.stream = _make_music_loop()
	smash_stream = _make_tone(260.0, 0.12, true)
	mistake_stream = _make_tone(190.0, 0.24, false)
	ui_stream = _make_tone(560.0, 0.07, false)
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	set_music_enabled(bool(config.get_value("options", "music", true)))
	set_sfx_enabled(bool(config.get_value("options", "sfx", true)))
	set_fullscreen(bool(config.get_value("options", "fullscreen", false)))


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if not is_instance_valid(music_player):
		return
	if enabled:
		if not music_player.playing:
			music_player.play()
	else:
		music_player.stop()


func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled


func set_fullscreen(enabled: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func play_smash() -> void:
	_play(smash_stream)


func play_slice() -> void:
	play_smash()


func play_mistake() -> void:
	_play(mistake_stream)


func play_ui() -> void:
	_play(ui_stream)


func sliced_stream() -> AudioStreamWAV:
	return smash_stream


func _play(stream: AudioStreamWAV) -> void:
	if not sfx_enabled or not is_instance_valid(sfx_player) or stream == null:
		return
	sfx_player.stream = stream
	sfx_player.play()


func _make_music_loop() -> AudioStreamWAV:
	var beat_length := 0.5
	var beats := 8
	var sample_count := int(SAMPLE_RATE * beat_length * beats)
	var notes := [392.0, 493.88, 587.33, 493.88, 440.0, 523.25, 659.25, 523.25]
	var samples := PackedByteArray()
	samples.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var time := float(sample_index) / SAMPLE_RATE
		var beat := int(time / beat_length) % beats
		var local_time := fmod(time, beat_length)
		var envelope := minf(1.0, local_time * 18.0) * minf(1.0, (beat_length - local_time) * 5.0)
		var note: float = notes[beat]
		var value := (sin(TAU * note * time) * 0.07 + sin(TAU * (note / 2.0) * time) * 0.035) * envelope
		samples.encode_s16(sample_index * 2, int(value * 12000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = sample_count
	stream.data = samples
	return stream


func _make_tone(frequency: float, duration: float, descending: bool) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var samples := PackedByteArray()
	samples.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var time := float(sample_index) / SAMPLE_RATE
		var progress := time / duration
		var note_frequency := lerpf(frequency, frequency * (0.66 if descending else 1.35), progress)
		var envelope := (1.0 - progress) * minf(1.0, progress * 35.0)
		var value := sin(TAU * note_frequency * time) * envelope * 0.28
		samples.encode_s16(sample_index * 2, int(value * 18000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = samples
	return stream
