extends Node

# Simple audio manager for the platformer
# Uses generated tones - no external audio files needed

var jump_player: AudioStreamPlayer
var coin_player: AudioStreamPlayer
var hurt_player: AudioStreamPlayer
var win_player: AudioStreamPlayer

func _ready():
	jump_player = AudioStreamPlayer.new()
	coin_player = AudioStreamPlayer.new()
	hurt_player = AudioStreamPlayer.new()
	win_player = AudioStreamPlayer.new()
	
	add_child(jump_player)
	add_child(coin_player)
	add_child(hurt_player)
	add_child(win_player)
	
	# Generate simple sounds
	jump_player.stream = generate_tone(440, 0.1, 0.3)
	coin_player.stream = generate_tone(880, 0.15, 0.4)
	hurt_player.stream = generate_tone(220, 0.2, 0.3)
	win_player.stream = generate_tone(660, 0.3, 0.5)

func generate_tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	var sample_rate = 44100
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		# Simple sine wave with envelope
		var envelope = 1.0
		var attack = 0.01
		var release = duration * 0.5
		
		if t < attack:
			envelope = t / attack
		elif t > duration - release:
			envelope = (duration - t) / release
		
		var sample = sin(2 * PI * freq * t) * envelope * volume
		var int_sample = int(sample * 32767)
		data.append(int_sample & 0xFF)
		data.append((int_sample >> 8) & 0xFF)
	
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return stream

func play_jump():
	if jump_player and not jump_player.playing:
		jump_player.play()

func play_coin():
	if coin_player and not coin_player.playing:
		coin_player.play()

func play_hurt():
	if hurt_player and not hurt_player.playing:
		hurt_player.play()

func play_win():
	if win_player and not win_player.playing:
		win_player.play()
