# Bala.gd
extends Area2D

const VELOCIDAD = 400.0 
var direccion = Vector2.ZERO # El Player establecerá esta dirección

func _physics_process(delta: float):
	global_position += direccion * VELOCIDAD * delta

# --- Función conectada a la señal 'area_entered' ---
# ¡IMPORTANTE! Conecta esta señal en el editor de Godot (nodo raíz Bala -> Pestaña Nodo -> Señales -> area_entered)
func _on_area_entered(area: Area2D):
	# Comprueba si el área que tocó está en el grupo "Enemigos"
	if area.is_in_group("Enemigos"):
		print("Bala tocó a un enemigo!")
		# Llama a la función 'morir' del enemigo si existe
		if area.has_method("morir"):
			area.morir() 
		
		queue_free() # La bala se destruye al tocar algo (enemigo o no)

# --- Función conectada a la señal 'screen_exited' ---
# ¡IMPORTANTE! Añade un nodo 'VisibleOnScreenNotifier2D' a tu Bala.tscn
# y conecta su señal 'screen_exited' a esta función.
func _on_screen_exited():
	queue_free() # La bala se destruye si sale de la pantalla para ahorrar recursos
