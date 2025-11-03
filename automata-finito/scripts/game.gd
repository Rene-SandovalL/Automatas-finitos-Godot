# game.gd
extends Node

# --- Referencias a Nodos ---
# Asumiendo: Game -> Nivel -> Player
@onready var player_instance = $Nivel/Player 

# --- Rutas de los nodos de la UI (según tus indicaciones) ---
@onready var input_line = $UI/BottomPanel/MarginContainer/contentLayout/MarginContainer/InputLayout/InputBox
@onready var execute_button = $UI/BottomPanel/MarginContainer/contentLayout/MarginContainer/InputLayout/ExecuteButton
@onready var status_label = $UI/BottomPanel/MarginContainer/contentLayout/MarginContainer/InputLayout/StatusLabel

# --- Ruta Asumida para AlphabetLabel ---
# (Basado en tu captura de pantalla de la UI, este label está fuera del InputLayout)
# (Si tu nodo se llama 'Alfabeto' en lugar de 'AlphabetLabel', cámbialo aquí)


# --- Alfabeto (Solo para mostrar en la UI) ---
# (Asegúrate de que coincida con tu imagen)
const ALFABETO = [
	"w: mover arriba",
	"s: mover abajo",
	"d: mover derecha",
	# (Añade el resto de tu alfabeto aquí)
]

func _ready():
	# Conecta el botón a la función
	execute_button.pressed.connect(_on_execute_pressed)
	# Conecta la tecla Enter del LineEdit
	input_line.text_submitted.connect(_on_execute_pressed)
	
	# Muestra el alfabeto en la UI
	status_label.text = "Introduce una palabra"

func _on_execute_pressed():
	var word = input_line.text.strip_edges() # Lee la palabra
	if word == "":
		status_label.text = "Introduce una palabra"
		return

	status_label.text = "Ejecutando..."
	input_line.text = "" # Limpia la caja
	
	# Llama a la función process_word en el Player
	var accepted = player_instance.process_word(word)
	
	if accepted:
		status_label.text = "Procesando palabra..."
	else:
		status_label.text = "¡Error! Ya hay una palabra en ejecución."
