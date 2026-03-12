extends Node

# Simple audio manager for the platformer
# Uses generated tones - no external audio files needed

var jump_player: AudioStreamPlayer
var coin_player: AudioStreamPlayer
var hurt_player: AudioStreamPlayer
var win_player: AudioStreamPlayer
var powerup_player: AudioStreamPlayer
var enemy_player: AudioStreamPlayer
var boss_player: AudioStreamPlayer
var checkpoint_player: AudioStreamPlayer

func _ready():
	jump_player = AudioStreamPlayer.new()
	coin_player = AudioStreamPlayer.new()
	hurt_player = AudioStreamPlayer.new()
	win_player = AudioStreamPlayer.new()
	powerup_player = AudioStreamPlayer.new()
	enemy_player = AudioStreamPlayer.new()
	boss_player = AudioStreamPlayer.new()
	checkpoint_player = AudioStreamPlayer.new()
	
	add_child(jump_player)
	add_child(coin_player)
	add_child(hurt_player)
	add_child(win_player)
	add_child(powerup_player)
	add_child(enemy_player)
	add_child(boss_player)
	add_child(checkpoint_player)
	
	# Generate simple sounds
	jump_player.stream = generate_tone(440, 0.1, 0.3)  # Jump - ascending
	coin_player.stream = generate_tone(880, 0.08, 0.4)  # Coin - high ping
	hurt_player.stream = generate_tone(180, 0.2, 0.3)  # Hurt - low
	win_player.stream = generate_tone(523, 0.15, 0.5)  # Win - C major arpeggio
	powerup_player.stream = generate_tone(660, 0.12, 0.5)  # Powerup - bright
	enemy_player.stream = generate_tone(300, 0.1, 0.3)  # Enemy defeated
	boss_player.stream = generate_tone(150, 0.3, 0.4)  # Boss warning - ominous
	checkpoint_player.stream = generate_tone(700, 0.15, 0.4)  # Checkpoint - ding

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

func play_powerup():
	if powerup_player and not powerup_player.playing:
		powerup_player.play()

func play_enemy():
	if enemy_player and not enemy_player.playing:
		enemy_player.play()

func play_boss_warning():
	if boss_player and not boss_player.playing:
		boss_player.play()

func play_checkpoint():
	if checkpoint_player and not checkpoint_player.playing:
		checkpoint_player.play()
