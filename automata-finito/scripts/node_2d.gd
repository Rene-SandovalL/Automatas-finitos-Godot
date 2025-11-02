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
