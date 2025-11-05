# game.gd
extends Node

# --- Constantes del Juego ---
const ZONAS_SEGURAS = [Vector2i(1, 2), Vector2i(3, 0)] 

# --- Referencias a Nodos ---
@onready var player_instance = $Nivel/Player 
@onready var spike_layer = $Nivel/SpikeLayer 
@onready var game_over_screen = $UI/GameOverScreen 
@onready var input_line = $UI/BottomPanel/MarginContainer/contentLayout/MarginContainer/InputLayout/InputBox
@onready var execute_button = $UI/BottomPanel/MarginContainer/contentLayout/MarginContainer/InputLayout/ExecuteButton
@onready var status_label = $UI/BottomPanel/MarginContainer/contentLayout/MarginContainer/InputLayout/StatusLabel
@onready var alphabet_label: Label = $UI/BottomPanel/MarginContainer/contentLayout/AlphabetLabel 
@onready var coin_label: Label = $UI.get_node("%CoinLabel") 
@onready var end_game_label: Label = $UI/GameOverScreen.get_node("%EndGameLabel")
@onready var restart_button: Button = $UI/GameOverScreen.get_node("%RestartButton")

# --- Alfabeto (Para mostrar en la UI) ---
const ALFABETO_TEXT = [
	"w: mover arriba", "s: mover abajo", "d: mover derecha",
	"i: disparar arriba", "j: disparar izquierda", "k: disparar abajo",
    "l: disparar derecha"
]
const ALFABETO = ["w", "s", "d", "i", "j", "k", "l"] 

var score: int = 0
var is_processing_ui: bool = false 

func _ready():
	execute_button.pressed.connect(_on_execute_pressed)
	input_line.text_submitted.connect(_on_execute_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	
#	alphabet_label.text = "ALFABETO\n" + "\n".join(ALFABETO_TEXT) 
	_reset_level()

func add_score(amount: int):
	score += amount
	_update_score_ui()

func _update_score_ui():
	coin_label.text = str(score).pad_zeros(2)

func _on_execute_pressed():
	var word = input_line.text.strip_edges()
	if word == "" or is_processing_ui:
		return

	_lock_ui() 
	
	var filtered_chars = []
	for char in word.to_lower():
		if char in ALFABETO:
			filtered_chars.append(char)
		else:
#			status_label.text = "¡ERROR! Carácter inválido: " + char
			_unlock_ui()
			return

	var success = await player_instance.process_word("".join(filtered_chars))
	
	if player_instance.is_dead: # El jugador murió durante la ejecución de la palabra
#		status_label.text = "¡ERROR! Te mató un enemigo."
		_show_end_screen(false) # Game Over
	elif success: # La palabra se completó sin que Isaac muriera por enemigo o comando inválido
		var final_state = player_instance.current_state
		if final_state in ZONAS_SEGURAS:
			# --- ¡NUEVA LÓGICA DE VICTORIA! ---
			if _hay_enemigos_vivos_en_zonas_seguras():
				#status_label.text = "¡ERROR! Enemigos vivos en zonas seguras."
				_show_end_screen(false) # Game Over
			else:
				#status_label.text = "¡Nivel Completado!"
				_show_end_screen(true) # ¡Victoria!
		else:
			status_label.text = "¡ERROR! Pisaste pinchos o no llegaste a una zona segura."
			_show_end_screen(false) # Game Over (Pinchos)
	else: # La palabra falló por un muro o comando inválido
		#status_label.text = "¡ERROR! Movimiento inválido o muro."
		_show_end_screen(false) # Game Over (Muro/Comando Inválido)

# --- NUEVA FUNCIÓN: Comprueba si hay enemigos vivos en zonas de aceptación ---
func _hay_enemigos_vivos_en_zonas_seguras() -> bool:
	# Obtiene todos los nodos del grupo "Enemigos"
	var enemigos_vivos = get_tree().get_nodes_in_group("Enemigos")
	
	for enemigo in enemigos_vivos:
		# Convertir la posición global del enemigo a una posición de celda (grid_pos)
		var enemigo_grid_pos = _world_to_grid(enemigo.global_position)
		
		# Si la posición del enemigo coincide con alguna de las zonas seguras
		if enemigo_grid_pos in ZONAS_SEGURAS:
			print("Enemigo detectado en zona segura: ", enemigo_grid_pos)
			return true # Hay al menos un enemigo vivo en una zona segura
			
	return false # No hay enemigos vivos en las zonas seguras

# --- Conversión de Coordenadas (NUEVA FUNCIÓN, para _hay_enemigos_vivos_en_zonas_seguras) ---
func _world_to_grid(world_pos: Vector2) -> Vector2i:
	# Invertir la lógica de _grid_to_world del Player
	var grid_x = (world_pos.x - (player_instance.TILE_SIZE / 10.0)) / player_instance.TILE_SIZE
	var grid_y = (world_pos.y - (player_instance.TILE_SIZE / 2.0)) / player_instance.TILE_SIZE
	
	# Restar el offset del tilemap para obtener la posición real en la cuadrícula del Player
	var final_grid_pos = Vector2(grid_x, grid_y) - player_instance.TILEMAP_OFFSET
	
	return Vector2i(round(final_grid_pos.x), round(final_grid_pos.y))


# --- Control de la Pantalla de Fin de Juego ---
func _show_end_screen(is_win: bool):
	if game_over_screen.visible: return # Evita llamar múltiples veces
	
	spike_layer.show() # Muestra los pinchos si es necesario
	
	if is_win:
		end_game_label.text = "¡SECUENCIA EXITOSA!"
		await player_instance.play_victory_animation()
	else:
		end_game_label.text = "GAME OVER"
		if not player_instance.is_dead: # Solo reproduce la animación si no está ya muriendo
			await player_instance.play_death_animation()
	
	game_over_screen.show()

func _on_restart_pressed():
	get_tree().reload_current_scene() 

func _reset_level():
	game_over_screen.hide()
	spike_layer.hide()
	score = 0
	_update_score_ui()
	_unlock_ui()

func _lock_ui():
	is_processing_ui = true
	input_line.editable = false
	execute_button.disabled = true

func _unlock_ui():
	is_processing_ui = false
	input_line.editable = true
	execute_button.disabled = false
