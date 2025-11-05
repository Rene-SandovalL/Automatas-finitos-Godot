# Bala.gd
extends Area2D

const VELOCIDAD = 400.0 
var direccion = Vector2.ZERO # ¡CAMBIO! El Player establecerá esto

func _physics_process(delta: float):
	global_position += direccion * VELOCIDAD * delta

# Conectado a la señal 'area_entered' de la Bala
func _on_area_entered(area: Area2D):
	if area.is_in_group("Enemigos"):
		# Llama a la función 'morir' del enemigo
		if area.has_method("morir"):
			area.morir() 
		
		queue_free()

# Conectado a la señal 'screen_exited'
func _on_screen_exited():
	queue_free()
