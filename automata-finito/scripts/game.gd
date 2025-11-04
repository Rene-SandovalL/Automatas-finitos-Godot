# game.gd
extends Node

# --- Constantes del Juego ---
const ZONAS_SEGURAS = [Vector2i(1, 2), Vector2i(3, 0)] 

@onready var player_instance = $Nivel/Player 

@onready var input_line = $UI/BottomPanel/MarginContainer/contentLayout/MarginContainer/InputLayout/InputBox
@onready var execute_button = $UI/BottomPanel/MarginContainer/contentLayout/MarginContainer/InputLayout/ExecuteButton
@onready var status_label = $UI/BottomPanel/MarginContainer/contentLayout/MarginContainer/InputLayout/StatusLabel
@onready var alphabet_label: Label = $UI/BottomPanel/MarginContainer/contentLayout/AlphabetLabel 

@onready var game_over_screen = $UI/GameOverScreen 
@onready var end_game_label: Label = $UI/GameOverScreen.get_node("%EndGameLabel")
@onready var restart_button: Button = $UI/GameOverScreen.get_node("%RestartButton")
@onready var spike_layer = $Nivel/SpikeLayer 

@onready var coin_label: Label = $UI.get_node("%CoinLabel") 

var score: int = 0
var is_processing_ui: bool = false 

const ALFABETO = ["w", "s", "d", "a", "i", "j", "k", "l", "f", "m"]

func _ready():
	execute_button.pressed.connect(_on_execute_pressed)
	input_line.text_submitted.connect(_on_execute_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	
	
	_reset_level()

# --- ¡NUEVA FUNCIÓN! ---
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
	
	var tokens_packed = word.to_lower().split("", false) 
	var tokens_array = Array(tokens_packed)
	var tokens = tokens_array.filter(func(token): return not token.is_empty())
	
	var success = await player_instance.process_word(word)
	
	if success:
		var final_state = player_instance.current_state
		if final_state in ZONAS_SEGURAS:
			_show_end_screen(true) 
		else:
			_show_end_screen(false)
	else:
		_show_end_screen(false)


func _show_end_screen(is_win: bool):
	spike_layer.show()
	
	if is_win:
		end_game_label.text = "¡SECUENCIA EXITOSA!"
		await player_instance.play_victory_animation()
	else:
		end_game_label.text = "GAME OVER"
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
