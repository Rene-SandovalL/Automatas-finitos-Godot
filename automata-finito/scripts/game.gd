
# game.gd
extends Node

# --- Constantes del Juego ---
const ZONAS_SEGURAS = [Vector2i(1, 2), Vector2i(3, 0)] 

# --- Referencias a Nodos ---
@onready var player_instance = $Nivel/Player 

# --- Rutas de los nodos de la UI (LAS QUE TÚ PROPORCIONASTE) ---
@onready var input_line = $UI/BottomPanel/MarginContainer/contentLayout/MarginContainer/InputLayout/InputBox
@onready var execute_button = $UI/BottomPanel/MarginContainer/contentLayout/MarginContainer/InputLayout/ExecuteButton
@onready var status_label = $UI/BottomPanel/MarginContainer/contentLayout/MarginContainer/InputLayout/StatusLabel
@onready var alphabet_label: Label = $UI/BottomPanel/MarginContainer/contentLayout/AlphabetLabel 

# --- Referencias a la Pantalla de Fin y Pinchos ---
@onready var game_over_screen = $UI/GameOverScreen 
@onready var end_game_label: Label = $UI/GameOverScreen/PanelContainer/MarginContainer/VBoxContainer/EndGameLabel
@onready var restart_button: Button = $UI/GameOverScreen/PanelContainer/MarginContainer/VBoxContainer/RestartButton
@onready var spike_layer = $Nivel/SpikeLayer 

# --- Alfabeto (Para mostrar en la UI) ---
const ALFABETO_TEXT = [
	"w: mover arriba",
	"s: mover abajo",
	"d: mover derecha",
	"i: apuntar arriba",
	"j: apuntar izquierda",
	"k: apuntar abajo",
	"l: apuntar derecha",
	"f: disparar",
    "m: dejar de apuntar"
]
# Alfabeto real para validación (¡Asegúrate de que 'a' esté si lo usas!)
const ALFABETO = ["w", "s", "d", "a", "i", "j", "k", "l", "f", "m"]

var is_processing_ui: bool = false 

func _ready():
	execute_button.pressed.connect(_on_execute_pressed)
	input_line.text_submitted.connect(_on_execute_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	
	#alphabet_label.text = "ALFABETO\n" + "\n".join(ALFABETO_TEXT) # <-- Respetando tu comentario
	
	_reset_level()

# ¡CORRECCIÓN! Esta función debe ser 'async' porque usa 'await'
func _on_execute_pressed():
	var word = input_line.text.strip_edges()
	if word == "" or is_processing_ui:
		return

	_lock_ui() 
	
	# Corrección de 'filter'
	var tokens_packed = word.to_lower().split("", false) 
	var tokens_array = Array(tokens_packed)
	var tokens = tokens_array.filter(func(token): return not token.is_empty())
	
	# Llama a la función process_word en el Player y ESPERA el resultado
	var success = await player_instance.process_word(word) # Pasas el string completo
	
	if success:
		var final_state = player_instance.current_state
		if final_state in ZONAS_SEGURAS:
			_show_end_screen(true) 
		else:
			_show_end_screen(false)
	else:
		_show_end_screen(false)

# --- Funciones de Control del Juego ---

# ¡CORRECCIÓN! Esta función debe ser 'async' porque usa 'await'
func _show_end_screen(is_win: bool):
	spike_layer.show()
	
	if is_win:
		end_game_label.text = "¡SECUENCIA EXITOSA!"
		# ¡NUEVO! Reproduce la animación de victoria
		await player_instance.play_victory_animation()
	else:
		end_game_label.text = "GAME OVER"
		# Reproduce la animación de muerte
		await player_instance.play_death_animation()
	
	game_over_screen.show()

func _on_restart_pressed():
	get_tree().reload_current_scene()

func _reset_level():
	game_over_screen.hide()
	spike_layer.hide()
	# player_instance.reset_to_start() # No es necesario, _ready() lo hará
	_unlock_ui()

func _lock_ui():
	is_processing_ui = true
	input_line.editable = false
	execute_button.disabled = true

func _unlock_ui():
	is_processing_ui = false
	input_line.editable = true
	execute_button.disabled = false
