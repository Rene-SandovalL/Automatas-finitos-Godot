# Player.gd
extends CharacterBody2D

# --- Constantes del Autómata ---
const TILE_SIZE = 64
const MOVEMENT_DURATION = 0.40 
const TILEMAP_OFFSET = Vector2(-1, -1) 

var BalaScene = preload("res://Scenes/Lagrima.tscn") 
var SonidoMuerte = preload("res://Assets/SFX/IsaacDies.wav") 
var is_busy: bool = false
var is_dead: bool = false 

# --- Estado Actual del Autómata ---
var current_state: Vector2i = Vector2i(0, 0)


# --- Transiciones Válidas (Movimiento) ---
var transitions = {
	Vector2i(0,0): {"d": Vector2i(1,0), "s": Vector2i(0,1)}, 
	Vector2i(1,0): {"d": Vector2i(2,0), "s": Vector2i(1,1)}, 
	Vector2i(2,0): {"d": Vector2i(3,0), "s": Vector2i(2,1)}, 
	Vector2i(3,0): {"s": Vector2i(3,1)}, 
	Vector2i(0,1): {"d": Vector2i(1,1), "s": Vector2i(0,2), "w": Vector2i(0,0)},
	Vector2i(1,1): {"d": Vector2i(2,1), "s": Vector2i(1,2), "w": Vector2i(1,0)},
	Vector2i(2,1): {"d": Vector2i(3,1), "s": Vector2i(2,2), "w": Vector2i(2,0)},
	Vector2i(3,1): {"s": Vector2i(3,2), "w": Vector2i(3,0)},
	Vector2i(0,2): {"d": Vector2i(1,2), "w": Vector2i(0,1)}, 
	Vector2i(1,2): {"d": Vector2i(2,2), "w": Vector2i(1,1)},
	Vector2i(2,2): {"d": Vector2i(3,2), "w": Vector2i(2,1)},
	Vector2i(3,2): {"w": Vector2i(3,1)}
}

var actions = ["i", "j", "k", "l"] 

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

func _execute_sequence(palabra: String) -> bool:
	var temp_state = current_state 
	
	for letra in palabra.to_lower(): 
		if is_dead:
			return _finish_processing(false)

		var command = String(letra) 
		
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
			
			if is_dead:
				return _finish_processing(false)
			
			animated_sprite.play("idle")
			
		elif command in actions:
			var shoot_dir = Vector2.ZERO
			var anim_shoot_string = "idle"
			
			match command:
				"i": shoot_dir = Vector2.UP; anim_shoot_string = "shoot_up"
				"j": shoot_dir = Vector2.LEFT; anim_shoot_string = "shoot_left"
				"k": shoot_dir = Vector2.DOWN; anim_shoot_string = "shoot_down"
				"l": shoot_dir = Vector2.RIGHT; anim_shoot_string = "shoot_right"
			
			animated_sprite.play(anim_shoot_string) 
			_shoot_bullet(shoot_dir) 
			await animated_sprite.animation_finished 
			
			if is_dead:
				return _finish_processing(false)

			animated_sprite.play("idle")
			
		else:
			print("¡ERROR! Movimiento o acción inválida '%s' desde %s" % [command, temp_state])
			return _finish_processing(false) 

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
		print("ADVERTENCIA: PuntoDeDisparo no encontrado. La bala sale del centro del Player.")
	bala.direccion = direction 

func morir_por_enemigo():
	if is_dead: return 
	is_dead = true
	is_busy = true 
	
	print("¡EL JUGADOR HA MUERTO POR ENEMIGO!")
	_play_sound(SonidoMuerte)
	animated_sprite.play("death") 
	
	await animated_sprite.animation_finished

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

func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	var final_tile_pos = Vector2(grid_pos) + TILEMAP_OFFSET
	var world_x = (final_tile_pos.x * TILE_SIZE) + (TILE_SIZE / 10.0) 
	var world_y = (final_tile_pos.y * TILE_SIZE) + (TILE_SIZE / 2.0)
	return Vector2(world_x, world_y)
