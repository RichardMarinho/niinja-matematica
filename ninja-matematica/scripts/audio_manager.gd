extends Node

signal accessibility_profile_updated

const SETTINGS_PATH := "user://ninja_matematica.cfg"
const SAMPLE_RATE := 22050
const MUSIC_BEAT_SECONDS := 0.75
const MUSIC_BAR_COUNT := 8

var music_player: AudioStreamPlayer
var effect_players: Array[AudioStreamPlayer] = []
var music_enabled := true
var sfx_enabled := true
var smash_stream: AudioStreamWAV
var mistake_stream: AudioStreamWAV
var correct_stream: AudioStreamWAV
var ui_stream: AudioStreamWAV
var hover_stream: AudioStreamWAV
var _next_effect_player := 0
var _last_hover_msec := -1000
var sfx_preference_enabled := true
var accessibility_sfx_enabled := true
var accessibility_profile := {"version": 1, "audioAssistance": false, "soundEffects": "on"}
var accessibility_profile_received := false
var accessibility_callback_ref: JavaScriptObject
var protected_accessibility_speech := false
var protected_speech_started_msec := 0
var queued_accessibility_speech := ""
var queued_accessibility_protected := false
var queued_speech_hover_source: Object = null
var active_speech_hover_source: Object = null
var pending_speech_until_profile := ""
var pending_speech_hover_source: Object = null


func _ready() -> void:
	get_tree().node_added.connect(_on_scene_node_added)
	call_deferred("_connect_current_scene_buttons")
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if (window.speechSynthesis) window.speechSynthesis.getVoices();")
	else:
		DisplayServer.tts_get_voices()
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.volume_db = -22.0
	add_child(music_player)
	for player_index in range(4):
		var player := AudioStreamPlayer.new()
		player.name = "EffectPlayer%d" % player_index
		player.volume_db = -8.0
		add_child(player)
		effect_players.append(player)
	music_player.stream = _make_music_loop()
	smash_stream = _make_tone(250.0, 0.11, true, 0.22)
	mistake_stream = _make_note_sequence([293.66, 220.0], 0.14, 0.025, 0.22)
	correct_stream = _make_note_sequence([523.25, 659.25, 783.99], 0.12, 0.018, 0.18)
	ui_stream = _make_note_sequence([740.0, 988.0], 0.045, 0.012, 0.12)
	hover_stream = _make_tone(1046.5, 0.045, false, 0.085)
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	set_music_enabled(bool(config.get_value("options", "music", true)))
	set_sfx_enabled(bool(config.get_value("options", "sfx", true)))
	set_fullscreen(bool(config.get_value("options", "fullscreen", false)))
	if OS.has_feature("web"):
		_install_accessibility_profile_bridge()


func _install_accessibility_profile_bridge() -> void:
	var window := JavaScriptBridge.get_interface("window")
	accessibility_callback_ref = JavaScriptBridge.create_callback(_on_accessibility_profile_message)
	window.__gaussAudioAccessibilityCallback = accessibility_callback_ref
	JavaScriptBridge.eval("""
		(function() {
			if (!window.__gaussAudioAccessibilityListener) {
				window.__gaussAudioAccessibilityListener = function(event) {
					if (event.origin !== window.location.origin || event.source !== window.parent) return;
					if (!event.data || event.data.type !== 'gauss-accessibility-profile') return;
					if (typeof window.__gaussAudioAccessibilityCallback === 'function')
						window.__gaussAudioAccessibilityCallback(JSON.stringify(event.data));
				};
				window.addEventListener('message', window.__gaussAudioAccessibilityListener);
			}
			if (window.parent !== window)
				window.parent.postMessage({type: 'gauss-accessibility-ready'}, window.location.origin);
		})()
	""")


func _on_accessibility_profile_message(args: Array) -> void:
	if args.is_empty() or not args[0] is String:
		return
	var envelope: Variant = JSON.parse_string(str(args[0]))
	if not envelope is Dictionary or int(envelope.get("version", 0)) != 1 or not envelope.get("profile") is Dictionary:
		return
	var profile: Dictionary = envelope.profile
	if int(profile.get("version", 0)) != 1:
		return
	if typeof(profile.get("audioAssistance")) != TYPE_BOOL or not ["on", "off"].has(profile.get("soundEffects")):
		return
	set_accessibility_profile(profile)


func set_accessibility_profile(profile: Dictionary) -> void:
	accessibility_profile = profile.duplicate(true)
	accessibility_profile_received = true
	set_accessibility_sound_effects(profile.soundEffects == "on")
	if not is_audio_assistance_enabled():
		pending_speech_until_profile = ""
		pending_speech_hover_source = null
		stop_accessibility_speech()
	else:
		var pending_text := pending_speech_until_profile
		var pending_source := pending_speech_hover_source
		pending_speech_until_profile = ""
		pending_speech_hover_source = null
		if not pending_text.is_empty():
			call_deferred("speak_accessibility", pending_text, false, pending_source)
	accessibility_profile_updated.emit()


func is_audio_assistance_enabled() -> bool:
	return bool(accessibility_profile.get("audioAssistance", false))


func speak_option_state(option_name: String, enabled: bool, hover_source: Object = null) -> String:
	var labels := {
		"music": ["Música", "ativada", "desativada"],
		"sfx": ["Efeitos sonoros", "ativados", "desativados"],
		"hints": ["Dicas", "ativadas", "desativadas"],
		"fullscreen": ["Tela cheia", "ativada", "desativada"],
	}
	if not labels.has(option_name):
		return "unknown_option"
	var label: Array = labels[option_name]
	var text := "%s: %s." % [label[0], label[1] if enabled else label[2]]
	return speak_hover(text, hover_source) if hover_source != null else speak_accessibility(text)


func speak_hover(text: String, source: Object) -> String:
	if not is_instance_valid(source):
		return "not_hovered"
	source.set_meta("gauss_tts_hover_active", true)
	return speak_accessibility(text, false, source)


func speak_accessibility(text: String, protect_until_finished := false, hover_source: Object = null) -> String:
	if text.strip_edges().is_empty():
		return "disabled"
	if hover_source != null:
		if not is_instance_valid(hover_source) or not hover_source.has_meta("gauss_tts_hover_active") or not bool(hover_source.get_meta("gauss_tts_hover_active")):
			return "not_hovered"
	if not is_audio_assistance_enabled():
		if not accessibility_profile_received:
			pending_speech_until_profile = text
			pending_speech_hover_source = hover_source
		return "disabled"
	if protected_accessibility_speech:
		queued_accessibility_speech = text
		queued_accessibility_protected = protect_until_finished
		queued_speech_hover_source = hover_source
		return "queued"
	stop_accessibility_speech()
	if OS.has_feature("web"):
		var script := """
		(function(text) {
			if (!window.speechSynthesis || !window.SpeechSynthesisUtterance) return "unavailable";
			const synth = window.speechSynthesis;
			const voices = synth.getVoices();
			const isBrazilianPortuguese = (voice) => voice.lang.toLowerCase().replace("_", "-").startsWith("pt-br");
			const faberVoice = voices.find((voice) => /faber/i.test(voice.name + " " + voice.voiceURI) && isBrazilianPortuguese(voice));
			const deviceVoice = voices.find((voice) => isBrazilianPortuguese(voice)) || voices.find((voice) => voice.lang.toLowerCase().startsWith("pt"));
			const voice = faberVoice || deviceVoice;
			const utterance = new SpeechSynthesisUtterance(text);
			if (voice) utterance.voice = voice;
			utterance.lang = voice ? voice.lang : "pt-BR";
			synth.speak(utterance);
			return faberVoice ? "faber" : (voice ? "device_fallback" : "device_default");
		})(%s)
		""" % JSON.stringify(text)
		var result := str(JavaScriptBridge.eval(script))
		if result in ["faber", "device_fallback", "device_default"]:
			active_speech_hover_source = hover_source
		if protect_until_finished and result in ["faber", "device_fallback", "device_default"]:
			_protect_accessibility_speech()
		return result
	var voices := DisplayServer.tts_get_voices()
	for voice_info in voices:
		var voice_id := str(voice_info.get("id", ""))
		var voice_name := str(voice_info.get("name", ""))
		var voice_language := str(voice_info.get("language", "")).to_lower().replace("_", "-")
		if "faber" in (voice_id + " " + voice_name).to_lower() and voice_language.begins_with("pt-br"):
			DisplayServer.tts_speak(text, voice_id)
			active_speech_hover_source = hover_source
			if protect_until_finished:
				_protect_accessibility_speech()
			return "faber"
	var portuguese_voices := DisplayServer.tts_get_voices_for_language("pt_BR")
	if portuguese_voices.is_empty():
		portuguese_voices = DisplayServer.tts_get_voices_for_language("pt-BR")
	if portuguese_voices.is_empty():
		if voices.is_empty():
			return "no_portuguese_voice"
		DisplayServer.tts_speak(text, str(voices[0].get("id", "")))
	else:
		DisplayServer.tts_speak(text, portuguese_voices[0])
	active_speech_hover_source = hover_source
	if protect_until_finished:
		_protect_accessibility_speech()
	return "device_fallback"


func _protect_accessibility_speech() -> void:
	protected_accessibility_speech = true
	protected_speech_started_msec = Time.get_ticks_msec()


func _process(_delta: float) -> void:
	if not protected_accessibility_speech or Time.get_ticks_msec() - protected_speech_started_msec < 300:
		return
	var is_speaking := false
	if OS.has_feature("web"):
		is_speaking = bool(JavaScriptBridge.eval("!!(window.speechSynthesis && (window.speechSynthesis.speaking || window.speechSynthesis.pending))"))
	else:
		is_speaking = DisplayServer.tts_is_speaking()
	if not is_speaking:
		protected_accessibility_speech = false
		if not queued_accessibility_speech.is_empty():
			var queued_text := queued_accessibility_speech
			var queued_protected := queued_accessibility_protected
			var queued_source := queued_speech_hover_source
			queued_accessibility_speech = ""
			queued_accessibility_protected = false
			queued_speech_hover_source = null
			if queued_source == null or is_instance_valid(queued_source):
				call_deferred("speak_accessibility", queued_text, queued_protected, queued_source)


func stop_hover_speech(source: Object) -> void:
	if is_instance_valid(source):
		source.set_meta("gauss_tts_hover_active", false)
	if pending_speech_hover_source == source:
		pending_speech_until_profile = ""
		pending_speech_hover_source = null
	if queued_speech_hover_source == source:
		queued_accessibility_speech = ""
		queued_accessibility_protected = false
		queued_speech_hover_source = null
	if active_speech_hover_source == source and not protected_accessibility_speech:
		stop_accessibility_speech()


func stop_accessibility_speech() -> void:
	protected_accessibility_speech = false
	queued_accessibility_speech = ""
	queued_accessibility_protected = false
	queued_speech_hover_source = null
	active_speech_hover_source = null
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if (window.speechSynthesis) window.speechSynthesis.cancel();")
	else:
		DisplayServer.tts_stop()

func _connect_current_scene_buttons() -> void:
	var current_scene := get_tree().current_scene
	if current_scene:
		_connect_button_hover_recursively(current_scene)


func _on_scene_node_added(node: Node) -> void:
	if node is BaseButton:
		_connect_button_hover(node)


func _connect_button_hover_recursively(node: Node) -> void:
	if node is BaseButton:
		_connect_button_hover(node)
	for child in node.get_children():
		_connect_button_hover_recursively(child)


func _connect_button_hover(button: BaseButton) -> void:
	if button.has_meta("gauss_hover_sound_connected"):
		return
	button.set_meta("gauss_hover_sound_connected", true)
	button.mouse_entered.connect(_on_button_hover.bind(button))


func _on_button_hover(button: BaseButton) -> void:
	if not is_instance_valid(button) or button.disabled:
		return
	var now := Time.get_ticks_msec()
	if now - _last_hover_msec < 85:
		return
	_last_hover_msec = now
	_play(hover_stream)


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
	sfx_preference_enabled = enabled
	_sync_sfx_enabled()


func set_accessibility_sound_effects(enabled: bool) -> void:
	accessibility_sfx_enabled = enabled
	_sync_sfx_enabled()


func _sync_sfx_enabled() -> void:
	sfx_enabled = sfx_preference_enabled and accessibility_sfx_enabled
	if not sfx_enabled:
		for player in effect_players:
			player.stop()


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


func play_correct() -> void:
	_play(correct_stream)


func play_ui() -> void:
	_play(ui_stream)


func sliced_stream() -> AudioStreamWAV:
	return smash_stream


func _play(stream: AudioStreamWAV) -> void:
	if not sfx_enabled or effect_players.is_empty() or stream == null:
		return
	var selected_index := _next_effect_player
	for offset in range(effect_players.size()):
		var candidate_index := (_next_effect_player + offset) % effect_players.size()
		if not effect_players[candidate_index].playing:
			selected_index = candidate_index
			break
	_next_effect_player = (selected_index + 1) % effect_players.size()
	var player := effect_players[selected_index]
	player.stream = stream
	player.play()


func _make_music_loop() -> AudioStreamWAV:
	var beat_length := MUSIC_BEAT_SECONDS
	var bar_length := beat_length * 4.0
	var loop_length := bar_length * float(MUSIC_BAR_COUNT)
	var sample_count := int(round(SAMPLE_RATE * loop_length))
	var chords := [
		PackedFloat32Array([146.83, 174.61, 220.0, 261.63]),
		PackedFloat32Array([98.0, 123.47, 146.83, 174.61]),
		PackedFloat32Array([130.81, 164.81, 196.0, 246.94]),
		PackedFloat32Array([110.0, 130.81, 164.81, 196.0]),
		PackedFloat32Array([146.83, 174.61, 220.0, 261.63]),
		PackedFloat32Array([98.0, 123.47, 146.83, 174.61]),
		PackedFloat32Array([130.81, 164.81, 196.0, 246.94]),
		PackedFloat32Array([110.0, 130.81, 164.81, 196.0]),
	]
	var bass_roots := PackedFloat32Array([73.42, 49.0, 65.41, 55.0, 73.42, 49.0, 65.41, 55.0])
	var melody := PackedFloat32Array([
		587.33, 0.0, 440.0, 0.0, 523.25, 0.0, 440.0, 0.0,
		392.0, 0.0, 493.88, 0.0, 523.25, 0.0, 440.0, 0.0,
		587.33, 0.0, 440.0, 0.0, 523.25, 0.0, 659.25, 0.0,
		493.88, 0.0, 440.0, 0.0, 392.0, 0.0, 440.0, 0.0,
	])
	var samples := PackedByteArray()
	samples.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var time := float(sample_index) / float(SAMPLE_RATE)
		var beat_index := floori(time / beat_length) % melody.size()
		var bar_index := floori(float(beat_index) / 4.0) % MUSIC_BAR_COUNT
		var beat_position := fmod(time, beat_length)
		var bar_position := fmod(time, bar_length)
		var pad_envelope := minf(1.0, bar_position / 0.24) * minf(1.0, (bar_length - bar_position) / 0.42)
		var value := 0.0
		for frequency in chords[bar_index]:
			var warm_key := sin(TAU * frequency * time) + sin(TAU * frequency * 2.01 * time) * 0.16 + sin(TAU * frequency * 0.5 * time) * 0.08
			value += warm_key * pad_envelope * 0.018
		var bass_frequency: float = bass_roots[bar_index]
		var bass_envelope := minf(1.0, bar_position / 0.035) * exp(-bar_position * 0.42) * minf(1.0, (bar_length - bar_position) / 0.18)
		value += sin(TAU * bass_frequency * time) * bass_envelope * 0.075
		var melody_frequency: float = melody[beat_index]
		if melody_frequency > 0.0:
			var melody_envelope := minf(1.0, beat_position * 55.0) * exp(-beat_position * 4.2) * minf(1.0, (beat_length - beat_position) * 14.0)
			value += (sin(TAU * melody_frequency * time) + sin(TAU * melody_frequency * 2.0 * time) * 0.12) * melody_envelope * 0.055
		if beat_index % 4 == 0:
			value += sin(TAU * (52.0 + 86.0 * exp(-beat_position * 28.0)) * beat_position) * exp(-beat_position * 13.0) * 0.13
		elif beat_index % 4 == 2 and beat_position < 0.16:
			var noise_sample := sin(float(sample_index) * 12.9898) * 43758.5453
			var noise: float = (noise_sample - floor(noise_sample)) * 2.0 - 1.0
			value += noise * exp(-beat_position * 34.0) * 0.022
		if beat_index % 2 == 1 and beat_position < 0.045:
			value += sin(TAU * 6800.0 * beat_position) * exp(-beat_position * 72.0) * 0.012
		value = clampf(value, -0.82, 0.82)
		samples.encode_s16(sample_index * 2, int(value * 15500.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = samples
	return stream


func _make_tone(frequency: float, duration: float, descending: bool, amplitude: float) -> AudioStreamWAV:
	var sample_count := int(SAMPLE_RATE * duration)
	var samples := PackedByteArray()
	samples.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var time := float(sample_index) / float(SAMPLE_RATE)
		var progress := time / duration
		var note_frequency := lerpf(frequency, frequency * (0.66 if descending else 1.35), progress)
		var envelope := sin(PI * progress) * minf(1.0, progress * 45.0)
		var value := sin(TAU * note_frequency * time) * envelope * amplitude
		samples.encode_s16(sample_index * 2, int(value * 18000.0))
	return _make_wav(samples)


func _make_note_sequence(notes: Array, note_length: float, gap: float, amplitude: float) -> AudioStreamWAV:
	var step_length := note_length + gap
	var duration := note_length * float(notes.size()) + gap * float(notes.size() - 1)
	var sample_count := int(SAMPLE_RATE * duration)
	var samples := PackedByteArray()
	samples.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var time := float(sample_index) / float(SAMPLE_RATE)
		var note_index := mini(floori(time / step_length), notes.size() - 1)
		var note_time := fmod(time, step_length)
		var value := 0.0
		if note_time < note_length:
			var frequency: float = notes[note_index]
			var envelope := minf(1.0, note_time * 65.0) * exp(-note_time * 5.5) * minf(1.0, (note_length - note_time) * 32.0)
			value = (sin(TAU * frequency * note_time) + sin(TAU * frequency * 2.0 * note_time) * 0.08) * envelope * amplitude
		samples.encode_s16(sample_index * 2, int(value * 18000.0))
	return _make_wav(samples)


func _make_wav(samples: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = samples
	return stream
