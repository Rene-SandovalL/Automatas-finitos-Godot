extends CharacterBody2D

const TILE_SIZE = 64
const MOVEMENT_DURATION = 0.40 

const TILEMAP_OFFSET = Vector2(-1, -1) 

var SonidoMuerte = preload("res://Assets/SFX/IsaacDies.wav")
var is_processing: bool = false 

# --- Estado Actual del Autómata Unica variable ---
var current_state: Vector2i = Vector2i(0, 0) 

# --- Transiciones Válidas ---
var transitions = {
	# FILA 0 (arriba)
	Vector2i(0,0): {"d": Vector2i(1,0), "s": Vector2i(0,1)},
	Vector2i(1,0): {"d": Vector2i(2,0), "s": Vector2i(1,1)}, 
	Vector2i(2,0): {"d": Vector2i(3,0), "s": Vector2i(2,1)}, 
	Vector2i(3,0): {"s": Vector2i(3,1)}, 

	# FILA 1 (centro)
	Vector2i(0,1): {"d": Vector2i(1,1), "s": Vector2i(0,2), "w": Vector2i(0,0)},
	Vector2i(1,1): {"d": Vector2i(2,1), "s": Vector2i(1,2), "w": Vector2i(1,0)},
	Vector2i(2,1): {"d": Vector2i(3,1), "s": Vector2i(2,2), "w": Vector2i(2,0)},
	Vector2i(3,1): {"s": Vector2i(3,2), "w": Vector2i(3,0)}, 

	# FILA 2 (abajo)
	Vector2i(0,2): {"d": Vector2i(1,2), "w": Vector2i(0,1)}, 
	Vector2i(1,2): {"d": Vector2i(2,2), "w": Vector2i(1,1)},
	Vector2i(2,2): {"d": Vector2i(3,2), "w": Vector2i(2,1)},
	Vector2i(3,2): {"w": Vector2i(3,1)} 
}

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

func _ready():
	reset_to_start() 

func process_word(palabra: String) -> bool:
	if is_processing:
		return false 

	is_processing = true
	
	var success = await _execute_sequence(palabra)
	
	return success

func _execute_sequence(palabra: String) -> bool:
	var temp_state = current_state 
	
	for letra in palabra.to_lower(): 
		var command = String(letra) 
		
		if not transitions.has(temp_state):
			print("¡ERROR! Estado desconocido: ", temp_state)
			return _finish_processing(false) 

		var possible_moves = transitions[temp_state]
		
		if not possible_moves.has(command):
			print("¡ERROR! Movimiento inválido '%s' desde %s" % [command, temp_state])
			return _finish_processing(false) 

		temp_state = possible_moves[command] 
		
		var anim_string = "idle"
		match command:
			"w": anim_string = "walk_up"
			"s": anim_string = "walk_down"
			"d": anim_string = "walk_right"

		animated_sprite.play(anim_string)
		
		var tween = create_tween()
		var new_world_pos = _grid_to_world(temp_state)
		
		tween.tween_property(self, "global_position", new_world_pos, MOVEMENT_DURATION) 
		
		await tween.finished
		
		animated_sprite.play("idle")
	
	current_state = temp_state 
	return _finish_processing(true) 

func _finish_processing(success: bool) -> bool:
	is_processing = false
	if success:
		print("Palabra completada. Estado final: ", current_state)
	else:
		print("Palabra fallida.")
	return success


func play_death_animation():
	is_processing = true 
	
	_play_sound(SonidoMuerte)
	
	animated_sprite.play("death") 
	await animated_sprite.animation_finished

func play_victory_animation():
	is_processing = true
	animated_sprite.play("thumbs_up") 
	await animated_sprite.animation_finished

func reset_to_start():
	is_processing = false
	current_state = Vector2i(0, 0) 
	global_position = _grid_to_world(current_state) 
	animated_sprite.play("idle")

func _play_sound(stream: AudioStream):
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = stream
	audio_player.autoplay = true
	audio_player.volume_db = -5.0
	audio_player.finished.connect(audio_player.queue_free)
	get_tree().root.add_child(audio_player)

func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	var final_tile_pos = Vector2(grid_pos) + TILEMAP_OFFSET
	
	var world_x = (final_tile_pos.x * TILE_SIZE) + (TILE_SIZE / 10.0)
	var world_y = (final_tile_pos.y * TILE_SIZE) + (TILE_SIZE / 2.0)
	
	return Vector2(world_x, world_y)
