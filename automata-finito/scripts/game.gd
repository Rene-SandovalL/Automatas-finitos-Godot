# game.gd
extends Node

# --- Constantes del Juego ---
const ZONAS_SEGURAS = [Vector2i(1, 2), Vector2i(3, 0)] 

# --- Referencias a Nodos (usa @onready para asegurar que existan) ---
@onready var player_instance = $Nivel/Player 
@onready var spike_layer = $Nivel/SpikeLayer 
@onready var game_over_screen = $UI/GameOverScreen 
@onready var input_line = $UI/BottomPanel/MarginContainer/contentLayout/MarginContainer/InputLayout/InputBox
@onready var execute_button = $UI/BottomPanel/MarginContainer/contentLayout/MarginContainer/InputLayout/ExecuteButton
@onready var status_label = $UI/BottomPanel/MarginContainer/contentLayout/MarginContainer/InputLayout/StatusLabel
@onready var alphabet_label: Label = $UI/BottomPanel/MarginContainer/contentLayout/AlphabetLabel 
@onready var coin_label: Label = $UI.get_node("%CoinLabel") # Referencia por nombre único
@onready var end_game_label: Label = $UI/GameOverScreen.get_node("%EndGameLabel")
@onready var restart_button: Button = $UI/GameOverScreen.get_node("%RestartButton")

# --- Alfabeto (Para mostrar en la UI y validar input) ---
const ALFABETO_TEXT = [
	"w: mover arriba",
	"s: mover abajo",
	"a: mover izquierda",
	"d: mover derecha",
	"i: disparar arriba",
	"j: disparar izquierda",
	"k: disparar abajo",
    "l: disparar derecha"
]
const ALFABETO = ["w", "s", "a", "d", "i", "j", "k", "l"] # Alfabeto real para validación

var score: int = 0
var is_processing_ui: bool = false # Bloquea la UI mientras el Player procesa

func _ready():
	execute_button.pressed.connect(_on_execute_pressed)
	input_line.text_submitted.connect(_on_execute_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	
#	alphabet_label.text = "ALFABETO\n" + "\n".join(ALFABETO_TEXT) # Muestra el alfabeto en la UI
	
	_reset_level()

# --- Funciones de Puntuación ---
func add_score(amount: int):
	score += amount
	_update_score_ui()

func _update_score_ui():
	coin_label.text = str(score).pad_zeros(2)

# --- Lógica de Ejecución de Comandos ---
func _on_execute_pressed():
	var word = input_line.text.strip_edges()
	if word == "" or is_processing_ui:
		return

	_lock_ui() 
	
	# Filtra caracteres inválidos (según tu ALFABETO)
	var filtered_chars = []
	for char in word.to_lower():
		if char in ALFABETO:
			filtered_chars.append(char)
		else:
			status_label.text = "¡ERROR! Carácter inválido: " + char
			_unlock_ui()
			return

	# Llama a la función process_word en el Player y ESPERA el resultado
	var success = await player_instance.process_word("".join(filtered_chars))
	
	if player_instance.is_dead(): # Si el jugador murió durante la palabra (ej. por enemigo)
		_show_end_screen(false)
	elif success: # Si la palabra terminó exitosamente y no murió
		var final_state = player_instance.current_state
		if final_state in ZONAS_SEGURAS:
			_show_end_screen(true) # Victoria
		else:
			# Si no está en zona segura y no murió por enemigo, asumimos fallo por pinchos
			#status_label.text = "¡ERROR! Pisaste pinchos o no llegaste a una zona segura."
			_show_end_screen(false) # Derrota
	else: # Si la palabra falló por un muro o comando inválido
		#status_label.text = "¡ERROR! Comando inválido o muro."
		_show_end_screen(false) # Derrota

# --- Manejo de la Muerte del Player (centralizado aquí) ---
func _handle_player_death():
	# Se llama cuando el Player muere por un enemigo
	if game_over_screen.visible: return # Ya mostramos Game Over
	
	print("Game.gd recibió la señal de muerte del jugador.")
	#status_label.text = "¡ERROR! Te tocó un enemigo."
	_show_end_screen(false) # Muestra la pantalla de Game Over por derrota

# --- Control de la Pantalla de Fin de Juego ---
func _show_end_screen(is_win: bool):
	if game_over_screen.visible: return # Evita llamar múltiples veces
	
	spike_layer.show() # Muestra los pinchos si es necesario
	
	if is_win:
		end_game_label.text = "¡SECUENCIA EXITOSA!"
		await player_instance.play_victory_animation()
	else:
		end_game_label.text = "GAME OVER"
		# Solo reproduce la animación de muerte si el jugador no la está reproduciendo ya (ej. por enemigo)
		if not player_instance.is_dead():
			await player_instance.play_death_animation()
	
	game_over_screen.show()

func _on_restart_pressed():
	get_tree().reload_current_scene() # Reinicia la escena

func _reset_level():
	game_over_screen.hide()
	spike_layer.hide()
	score = 0
	_update_score_ui()
	_unlock_ui()

# --- Bloqueo/Desbloqueo de la UI ---
func _lock_ui():
	is_processing_ui = true
	input_line.editable = false
	execute_button.disabled = true

func _unlock_ui():
	is_processing_ui = false
	input_line.editable = true
	execute_button.disabled = false
