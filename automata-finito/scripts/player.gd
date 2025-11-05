# Player.gd
extends CharacterBody2D

# --- Constantes del Autómata ---
const TILE_SIZE = 64
const MOVEMENT_DURATION = 0.40 
const TILEMAP_OFFSET = Vector2(-1, -1)
var is_busy: bool = false
var is_dead: bool = false

var BalaScene = preload("res://Scenes/Lagrima.tscn") 
var SonidoMuerte = preload("res://Assets/SFX/IsaacDies.wav") 

# --- Estado Actual del Autómata ---
var current_state: Vector2i = Vector2i(0, 0)


# --- Transiciones  ---
var transitions = {
	# FILA 0 (arriba, y=0)
	Vector2i(0,0): {
		"s": Vector2i(0,1), "d": Vector2i(1,0), # Movimiento
		"i": Vector2i(0,0), "j": Vector2i(0,0), "k": Vector2i(0,0), "l": Vector2i(0,0) # Disparo
	},
	Vector2i(1,0): {
		"s": Vector2i(1,1), "d": Vector2i(2,0),
		"i": Vector2i(1,0), "j": Vector2i(1,0), "k": Vector2i(1,0), "l": Vector2i(1,0)
	},
	Vector2i(2,0): {
		"s": Vector2i(2,1), "d": Vector2i(3,0),
		"i": Vector2i(2,0), "j": Vector2i(2,0), "k": Vector2i(2,0), "l": Vector2i(2,0)
	},
	Vector2i(3,0): {
		"s": Vector2i(3,1), # Borde derecho
		"i": Vector2i(3,0), "j": Vector2i(3,0), "k": Vector2i(3,0), "l": Vector2i(3,0)
	},

	# FILA 1 (centro, y=1)
	Vector2i(0,1): {
		"w": Vector2i(0,0), "s": Vector2i(0,2), "d": Vector2i(1,1),
		"i": Vector2i(0,1), "j": Vector2i(0,1), "k": Vector2i(0,1), "l": Vector2i(0,1)
	},
	Vector2i(1,1): {
		"w": Vector2i(1,0), "s": Vector2i(1,2), "d": Vector2i(2,1),
		"i": Vector2i(1,1), "j": Vector2i(1,1), "k": Vector2i(1,1), "l": Vector2i(1,1)
	},
	Vector2i(2,1): {
		"w": Vector2i(2,0), "s": Vector2i(2,2), "d": Vector2i(3,1),
		"i": Vector2i(2,1), "j": Vector2i(2,1), "k": Vector2i(2,1), "l": Vector2i(2,1)
	},
	Vector2i(3,1): {
		"w": Vector2i(3,0), "s": Vector2i(3,2), # Borde derecho
		"i": Vector2i(3,1), "j": Vector2i(3,1), "k": Vector2i(3,1), "l": Vector2i(3,1)
	},

	# FILA 2 (abajo, y=2)
	Vector2i(0,2): {
		"w": Vector2i(0,1), "d": Vector2i(1,2), # Borde abajo
		"i": Vector2i(0,2), "j": Vector2i(0,2), "k": Vector2i(0,2), "l": Vector2i(0,2)
	},
	Vector2i(1,2): {
		"w": Vector2i(1,1), "d": Vector2i(2,2),
		"i": Vector2i(1,2), "j": Vector2i(1,2), "k": Vector2i(1,2), "l": Vector2i(1,2)
	},
	Vector2i(2,2): {
		"w": Vector2i(2,1), "d": Vector2i(3,2),
		"i": Vector2i(2,2), "j": Vector2i(2,2), "k": Vector2i(2,2), "l": Vector2i(2,2)
	},
	Vector2i(3,2): {
		"w": Vector2i(3,1), # Borde abajo-derecha
		"i": Vector2i(3,2), "j": Vector2i(3,2), "k": Vector2i(3,2), "l": Vector2i(3,2)
	}
}

# var actions = ["i", "j", "k", "l"] 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var punto_de_disparo: Marker2D = $PuntoDeDisparo 

func _ready():
	reset_to_start()
	add_to_group("Player") 

func process_word(palabra: String) -> bool:
	if is_busy: return false 
	is_busy = true
	is_dead = false
	var success = await _execute_sequence(palabra)
	return success

# --- Ejecutor de Secuencia (Unificado) ---
func _execute_sequence(palabra: String) -> bool:
	var temp_state = current_state 
	
	for letra in palabra.to_lower(): 
		if is_dead:
			return _finish_processing(false)

		var command = String(letra) 
		
		# --- Validación Unificada ---
		if not transitions.has(temp_state):
			print("¡ERROR! Estado desconocido: ", temp_state)
			return _finish_processing(false) # Fallo

		var possible_moves = transitions[temp_state]
		
		if not possible_moves.has(command):
			print("¡ERROR! Transición inválida '%s' desde %s" % [command, temp_state])
			return _finish_processing(false) 

		# --- 2. Obtener Siguiente Estado ---
		var next_state = possible_moves[command] 
		
		var anim_string = "idle"
		var shoot_dir = Vector2.ZERO
		var do_move = false

		match command:
			"w":
				anim_string = "walk_up"
				do_move = true
			"s":
				anim_string = "walk_down"
				do_move = true
			"d":
				anim_string = "walk_right"
				do_move = true
			"i":
				anim_string = "shoot_up"
				shoot_dir = Vector2.UP
			"j":
				anim_string = "shoot_left"
				shoot_dir = Vector2.LEFT
			"k":
				anim_string = "shoot_down"
				shoot_dir = Vector2.DOWN
			"l":
				anim_string = "shoot_right"
				shoot_dir = Vector2.RIGHT
			_:
				pass

		animated_sprite.play(anim_string)
			
		if do_move:
			var tween = create_tween()
			var new_world_pos = _grid_to_world(next_state)
			tween.tween_property(self, "global_position", new_world_pos, MOVEMENT_DURATION) 
			await tween.finished
			if is_dead: return _finish_processing(false)
		else:
			if shoot_dir != Vector2.ZERO:
				_shoot_bullet(shoot_dir) 
			
			await animated_sprite.animation_finished 
			if is_dead: return _finish_processing(false)
		
		animated_sprite.play("idle")
			
		# --- Actualizar Estado del Autómata ---
		temp_state = next_state 

	# --- Fin de la Palabra ---
	current_state = temp_state 
	return _finish_processing(not is_dead) 

func _finish_processing(success: bool) -> bool:
	is_busy = false
	if success: print("Palabra completada. Estado final: ", current_state)
	else: print("Palabra fallida.")
	return success

func _shoot_bullet(direction: Vector2):
	var bala = BalaScene.instantiate()
	get_tree().root.get_node("Game").add_child(bala)
	if punto_de_disparo:
		bala.global_position = punto_de_disparo.global_position
	else:
		bala.global_position = global_position 
		print("ADVERTENCIA: PuntoDeDisparo no encontrado.")
	bala.direccion = direction 

# --- Funciones de Control ---
func morir_por_enemigo():
	if is_dead: return 
	is_dead = true
	is_busy = true 
	
	print("¡EL JUGADOR HA MUERTO POR ENEMIGO!")
	_play_sound(SonidoMuerte)
	animated_sprite.play("death") 
	
	await animated_sprite.animation_finished
	get_tree().root.get_node("Game").call_deferred("_handle_player_death")

func play_death_animation(): 
	if is_dead: return
	is_dead = true
	is_busy = true 
	_play_sound(SonidoMuerte)
	animated_sprite.play("death") 
	await animated_sprite.animation_finished

func play_victory_animation(): 
	if is_dead: return
	is_busy = true
	animated_sprite.play("thumbs_up") 
	await animated_sprite.animation_finished

func reset_to_start():
	is_busy = false
	is_dead = false 
	current_state = Vector2i(0, 0) 
	global_position = _grid_to_world(current_state) 
	animated_sprite.play("idle")

func _play_sound(stream: AudioStream):
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = stream
	audio_player.autoplay = true
	audio_player.finished.connect(audio_player.queue_free)
	get_tree().root.add_child(audio_player)

# --- Función de Coordenadas ---
func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	var final_tile_pos = Vector2(grid_pos) + TILEMAP_OFFSET
	var world_x = (final_tile_pos.x * TILE_SIZE) + (TILE_SIZE / 10.0) 
	var world_y = (final_tile_pos.y * TILE_SIZE) + (TILE_SIZE / 2.0)
	return Vector2(world_x, world_y)
