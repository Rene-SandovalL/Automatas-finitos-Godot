# Player.gd
extends CharacterBody2D

# --- Constantes del Autómata ---
const TILE_SIZE = 64
const MOVEMENT_DURATION = 0.40 
const TILEMAP_OFFSET = Vector2(-1, -1) # Tu offset para alinear a Isaac

# --- Precarga de Recursos ---
# ¡IMPORTANTE! Revisa que estas rutas sean CORRECTAS para tus archivos.
var BalaScene = preload("res://Scenes/Lagrima.tscn") 
var SonidoMuerte = preload("res://Assets/SFX/IsaacDies.wav") 

# --- Estado Actual del Autómata ---
var current_state: Vector2i = Vector2i(0, 0)
var is_busy: bool = false # Bloquea nuevas acciones mientras una está en curso

# --- Transiciones Válidas (Movimiento) ---
var transitions = {
	# FILA 0 (arriba, y=0)
	Vector2i(0,0): {"d": Vector2i(1,0), "s": Vector2i(0,1)}, 
	Vector2i(1,0): {"a": Vector2i(0,0), "d": Vector2i(2,0), "s": Vector2i(1,1)}, 
	Vector2i(2,0): {"a": Vector2i(1,0), "d": Vector2i(3,0), "s": Vector2i(2,1)}, 
	Vector2i(3,0): {"a": Vector2i(2,0), "s": Vector2i(3,1)}, 

	# FILA 1 (centro, y=1)
	Vector2i(0,1): {"d": Vector2i(1,1), "s": Vector2i(0,2), "w": Vector2i(0,0)},
	Vector2i(1,1): {"a": Vector2i(0,1), "d": Vector2i(2,1), "s": Vector2i(1,2), "w": Vector2i(1,0)},
	Vector2i(2,1): {"a": Vector2i(1,1), "d": Vector2i(3,1), "s": Vector2i(2,2), "w": Vector2i(2,0)},
	Vector2i(3,1): {"a": Vector2i(2,1), "s": Vector2i(3,2), "w": Vector2i(3,0)},

	# FILA 2 (abajo, y=2)
	Vector2i(0,2): {"d": Vector2i(1,2), "w": Vector2i(0,1)}, 
	Vector2i(1,2): {"a": Vector2i(0,2), "d": Vector2i(2,2), "w": Vector2i(1,1)},
	Vector2i(2,2): {"a": Vector2i(1,2), "d": Vector2i(3,2), "w": Vector2i(2,1)},
	Vector2i(3,2): {"a": Vector2i(2,2), "w": Vector2i(3,1)}
}

# --- Comandos de Acción (disparo con i,j,k,l) ---
var actions = ["i", "j", "k", "l"] 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var punto_de_disparo: Marker2D = $PuntoDeDisparo # ¡Asegúrate de que este nodo exista como hijo directo del Player!

func _ready():
	reset_to_start()
	add_to_group("Player") # ¡IMPORTANTE! Añade el Player al grupo "Player"

# --- Función Pública para procesar la palabra ---
func process_word(palabra: String) -> bool:
	if is_busy: 
		print("Player está ocupado, ignorando palabra: ", palabra)
		return false 
	is_busy = true
	var success = await _execute_sequence(palabra)
	return success

# --- Ejecutor de Secuencia (Paso a Paso de los comandos) ---
func _execute_sequence(palabra: String) -> bool:
	var temp_state = current_state 
	
	for letra in palabra.to_lower(): 
		if is_dead(): # Si muere en medio de la palabra, detener
			return _finish_processing(false)

		var command = String(letra) 
		
		# --- 1. ¿Es un movimiento válido? ---
		if transitions.has(temp_state) and transitions[temp_state].has(command):
			temp_state = transitions[temp_state][command] 
			
			var anim_string = "idle"
			match command:
				"w": anim_string = "walk_up"
				"s": anim_string = "walk_down"
				"a": anim_string = "walk_left"
				"d": anim_string = "walk_right" 

			animated_sprite.play(anim_string)
			var tween = create_tween()
			var new_world_pos = _grid_to_world(temp_state)
			tween.tween_property(self, "global_position", new_world_pos, MOVEMENT_DURATION) 
			await tween.finished
			animated_sprite.play("idle")
			
		# --- 2. ¿Es una acción de disparo válida? ---
		elif command in actions:
			var shoot_dir = Vector2.ZERO
			var anim_shoot_string = "idle"
			
			match command:
				"i": # Disparar Arriba
					shoot_dir = Vector2.UP
					anim_shoot_string = "shoot_up"
				"j": # Disparar Izquierda
					shoot_dir = Vector2.LEFT
					anim_shoot_string = "shoot_left"
				"k": # Disparar Abajo
					shoot_dir = Vector2.DOWN
					anim_shoot_string = "shoot_down"
				"l": # Disparar Derecha
					shoot_dir = Vector2.RIGHT
					anim_shoot_string = "shoot_right"
			
			# 1. Reproduce la animación
			animated_sprite.play(anim_shoot_string) 
			
			# 2. ¡DISPARA LA BALA INMEDIATAMENTE! (No espera a que termine la animación)
			_shoot_bullet(shoot_dir) 
			
			# 3. Espera a que termine la animación de Isaac
			await animated_sprite.animation_finished 
			
			# 4. Vuelve a idle
			animated_sprite.play("idle")
			
		else:
			# --- Comando inválido o muro ---
			print("¡ERROR! Movimiento o acción inválida '%s' desde %s" % [command, temp_state])
			return _finish_processing(false) # Fallo

	current_state = temp_state 
	return _finish_processing(true) # Éxito

func _finish_processing(success: bool) -> bool:
	is_busy = false
	if success: print("Palabra completada. Estado final: ", current_state)
	else: print("Palabra fallida.")
	return success

# --- Creación y Disparo de la Bala ---
func _shoot_bullet(direction: Vector2):
	var bala = BalaScene.instantiate()
	get_tree().root.get_node("Game").add_child(bala) # Añade la bala a la escena Game
	
	# Asegurarse de que punto_de_disparo no sea null
	if punto_de_disparo:
		bala.global_position = punto_de_disparo.global_position
	else:
		# Fallback si el Marker2D no se encuentra (revisa tu escena Player.tscn)
		bala.global_position = global_position 
		print("ADVERTENCIA: PuntoDeDisparo no encontrado. La bala sale del centro del Player.")
	
	bala.direccion = direction 

# --- Lógica de Muerte del Player (cuando un enemigo lo toca) ---
func morir_por_enemigo():
	if is_dead(): return # Si ya estamos muertos o muriendo, no hacer nada

	is_busy = true # Bloquea nuevas acciones
	print("¡EL JUGADOR HA MUERTO POR ENEMIGO!")
	
	_play_sound(SonidoMuerte)
	animated_sprite.play("death") 
	await animated_sprite.animation_finished
	
	# Notifica a game.gd para manejar la pantalla final
	get_tree().root.get_node("Game").call_deferred("_handle_player_death")

# --- Lógica de Muerte del Player (cuando pisa pinchos o palabra fallida) ---
func play_death_animation(): 
	if is_dead(): return
	
	is_busy = true 
	_play_sound(SonidoMuerte)
	animated_sprite.play("death") 
	await animated_sprite.animation_finished

# --- Otras animaciones de estado ---
func play_victory_animation(): 
	if is_dead(): return
	
	is_busy = true
	animated_sprite.play("thumbs_up") 
	await animated_sprite.animation_finished

func reset_to_start():
	is_busy = false
	current_state = Vector2i(0, 0) 
	global_position = _grid_to_world(current_state) 
	animated_sprite.play("idle")

func is_dead() -> bool:
	# Esto es una simplificación, podrías tener una variable 'is_alive'
	return animated_sprite.animation == "death" && animated_sprite.is_playing()

# --- Funciones Auxiliares ---
func _play_sound(stream: AudioStream):
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = stream
	audio_player.autoplay = true
	audio_player.finished.connect(audio_player.queue_free) # Se auto-destruye al terminar
	get_tree().root.add_child(audio_player) # Añade el AudioPlayer a la raíz

# --- Conversión de Coordenadas ---
func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	var final_tile_pos = Vector2(grid_pos) + TILEMAP_OFFSET
	var world_x = (final_tile_pos.x * TILE_SIZE) + (TILE_SIZE / 10.0) # Ajustes finos
	var world_y = (final_tile_pos.y * TILE_SIZE) + (TILE_SIZE / 2.0)
	return Vector2(world_x, world_y)
