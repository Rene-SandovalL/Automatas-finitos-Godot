extends CharacterBody2D

"""
extends CharacterBody2D

@export var speed = 200.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

var last_direction = "down"

func _physics_process(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	
	if input_direction.length() > 0:
		velocity = input_direction.normalized() * speed
	else:
		velocity = Vector2.ZERO 

	move_and_slide()
	
	update_animation(input_direction)

func update_animation(input_direction):
	if input_direction.length() > 0:
		if input_direction.x < 0:
			last_direction = "left"
		elif input_direction.x > 0:
			last_direction = "right"
		elif input_direction.y < 0:
			last_direction = "up"
		elif input_direction.y > 0:
			last_direction = "down"
		
		animated_sprite.play("walk_" + last_direction)
	else:
		animated_sprite.play("idle")
"""

"""
# Player.gd
# REEMPLAZA todo tu script de Player con esto.
# Player.gd
# ¡REEMPLAZA todo tu script de Player con este!
extends CharacterBody2D

var speed := 1.0 # Velocidad del movimiento (afecta la duración del tween)
var direction := Vector2.ZERO # Dirección del movimiento actual
var cell_size := 64 # Tamaño de un tile en píxeles
var is_moving := false # Bandera para saber si el jugador está en movimiento

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite # Referencia a tu AnimatedSprite2D

func _ready():
	# Asegúrate de que el personaje esté en 'idle' al inicio
	animated_sprite.play("idle")

func _input(event: InputEvent) -> void:
	# Si ya se está moviendo, ignorar nuevas entradas de dirección
	if is_moving:
		return 

	# Solo procesar si es una tecla presionada y no estamos moviendo
	if event is InputEventKey and event.pressed and not is_moving:
		var new_direction = Vector2.ZERO
		
		if event.keycode == KEY_UP:
			new_direction = Vector2.UP
		elif event.keycode == KEY_DOWN:
			new_direction = Vector2.DOWN
		elif event.keycode == KEY_LEFT:
			new_direction = Vector2.LEFT
		elif event.keycode == KEY_RIGHT:
			new_direction = Vector2.RIGHT
			
		# Si se detectó una nueva dirección válida, iniciar el movimiento
		if new_direction != Vector2.ZERO:
			direction = new_direction # Actualiza la dirección actual del jugador
			move_to_next_tile()

func move_to_next_tile() -> void:
	is_moving = true
	
	# Reproducir la animación de caminar correspondiente
	if direction == Vector2.UP:
		animated_sprite.play("walk_up")
	elif direction == Vector2.DOWN:
		animated_sprite.play("walk_down")
	elif direction == Vector2.LEFT:
		animated_sprite.play("walk_left")
	elif direction == Vector2.RIGHT:
		animated_sprite.play("walk_right")
	
	var tween = create_tween()
	# Aseguramos que el movimiento se realice en coordenadas globales para mayor robustez
	var new_position = global_position + direction * cell_size
	
	# El tween moverá el personaje a la nueva posición global
	# La duración es 1.0 / speed, así que mayor 'speed' = más rápido
	tween.tween_property(self, "global_position", new_position, 1.0 / speed)
	
	# Cuando el movimiento termina, llamamos a move_finish
	tween.tween_callback(move_finish)

func move_finish() -> void:
	is_moving = false
	# Una vez que el movimiento termina, volvemos a la animación 'idle'
	animated_sprite.play("idle")

# Nota: El _physics_process ya no es necesario para el movimiento continuo
# Si solo necesitas actualizar la velocidad de CharacterBody2D para colisiones,
# podrías hacerlo, pero para el movimiento basado en Tween no es directo aquí.
# Si tus colisiones no son complejas, mover la 'position' o 'global_position'
# directamente (como hace el tween) funciona para un juego tile-based simple.
"""
# Player.gd (o como se llame tu script en el nodo Player)

# --- Constantes del Autómata ---
const TILE_SIZE = 64
const MOVEMENT_DURATION = 0.40 # Duración del movimiento en segundos

# --- ¡LA CLAVE DEL POSICIONAMIENTO! ---
# Basado en tu imagen, el suelo (0,0) está en el tile (1,1) del TileMap.
const TILEMAP_OFFSET = Vector2i(-1.5, -1) 

# --- Estado Actual del Autómata ---
var current_state: Vector2i = Vector2i(0, 0) # Estado inicial (0,0 lógico)
var is_processing: bool = false # Bloquea el autómata

# --- Transiciones Válidas (Usando tu lógica 0-indexada) ---
# Si un movimiento no está aquí, es un muro (falla).
var transitions = {
	# FILA 0 (arriba)
	Vector2i(0,0): {"d": Vector2i(1,0), "s": Vector2i(0,1)}, # inicio
	Vector2i(1,0): {"d": Vector2i(2,0), "s": Vector2i(1,1)}, 
	Vector2i(2,0): {"d": Vector2i(3,0), "s": Vector2i(2,1)}, 
	Vector2i(3,0): {"s": Vector2i(3,1)}, # Borde derecho

	# FILA 1 (centro)
	Vector2i(0,1): {"d": Vector2i(1,1), "s": Vector2i(0,2), "w": Vector2i(0,0)},
	Vector2i(1,1): {"d": Vector2i(2,1), "s": Vector2i(1,2), "w": Vector2i(1,0)},
	Vector2i(2,1): {"d": Vector2i(3,1), "s": Vector2i(2,2), "w": Vector2i(2,0)},
	Vector2i(3,1): {"s": Vector2i(3,2), "w": Vector2i(3,0)}, # Borde derecho

	# FILA 2 (abajo)
	Vector2i(0,2): {"d": Vector2i(1,2), "w": Vector2i(0,1)}, # Borde abajo
	Vector2i(1,2): {"d": Vector2i(2,2), "w": Vector2i(1,1)},
	Vector2i(2,2): {"d": Vector2i(3,2), "w": Vector2i(2,1)},
	Vector2i(3,2): {"w": Vector2i(3,1)} # Borde abajo-derecha
}

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

func _ready():
	# Establece el estado inicial y la posición visual
	current_state = Vector2i(0, 0)
	global_position = _grid_to_world(current_state)
	animated_sprite.play("idle") # Asumiendo que tienes anim "idle"

# --- Función Pública ---
# game.gd llamará a esta función
func process_word(palabra: String) -> bool:
	if is_processing:
		return false # Ya está procesando una palabra

	is_processing = true
	
	# Iniciamos un proceso asíncrono para movernos
	_execute_sequence(palabra)
	
	# Devolvemos 'true' inmediatamente para que la UI sepa que se aceptó
	# (El resultado real se verá en la animación)
	return true 

# --- Ejecutor de Secuencia (Paso a Paso) ---
func _execute_sequence(palabra: String):
	var temp_state = current_state # Usamos un estado temporal para la ejecución
	
	for letra in palabra.to_lower(): # Usamos to_lower() para consistencia
		var command = String(letra) # Convertir char a String
		
		# --- 1. Validación del Autómata ---
		if not transitions.has(temp_state):
			print("¡ERROR! Estado desconocido: ", temp_state)
			_finish_processing(false) # Fallo
			return

		var possible_moves = transitions[temp_state]
		
		if not possible_moves.has(command):
			print("¡ERROR! Movimiento inválido '%s' desde %s" % [command, temp_state])
			_finish_processing(false) # Fallo (chocó con muro)
			return

		# --- 2. Transición de Estado (Lógica) ---
		temp_state = possible_moves[command] # Actualiza el estado lógico
		
		# --- 3. Transición Visual (Animación y Tween) ---
		var anim_string = "idle"
		match command:
			"w": anim_string = "walk_up"
			"s": anim_string = "walk_down"
			"d": anim_string = "walk_right"
			# (Aquí añadirías "a": "walk_left" si existiera)

		animated_sprite.play(anim_string)
		
		var tween = create_tween()
		var new_world_pos = _grid_to_world(temp_state)
		
		# Mueve el sprite suavemente
		tween.tween_property(self, "global_position", new_world_pos, 0.25) # 0.25 seg
		
		# ¡ESPERA! Pausa la ejecución hasta que el tween termine
		await tween.finished
		
		animated_sprite.play("idle")
	
	# --- 4. Fin de la Palabra ---
	# Si el bucle termina, la palabra fue exitosa
	current_state = temp_state # Actualiza el estado real
	_finish_processing(true) # Éxito

func _finish_processing(success: bool):
	is_processing = false
	# Aquí puedes emitir una señal si game.gd necesita saber el resultado final
	if success:
		print("Palabra completada. Estado final: ", current_state)
	else:
		print("Palabra fallida.")
		# (Aquí podrías revertir al estado inicial si quieres)
		# current_state = Vector2i(0,0)
		# global_position = _grid_to_world(current_state)

# --- ¡LA FUNCIÓN CLAVE CORREGIDA! ---
# Convierte Lógica (0,0) -> Píxeles (96, 96)
func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	# 1. Suma el offset de la pared
	# (0,0) Lógico + (1,1) Offset = (1,1) Visual
	var final_tile_pos = grid_pos + TILEMAP_OFFSET
	
	# 2. Convierte la posición del tile visual a píxeles y centra
	var world_x = (final_tile_pos.x * TILE_SIZE) + (TILE_SIZE / 10.0)
	var world_y = (final_tile_pos.y * TILE_SIZE) + (TILE_SIZE / 2.0)
	
	return Vector2(world_x, world_y)
