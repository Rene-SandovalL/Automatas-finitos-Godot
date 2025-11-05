# Enemigo.gd
extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D

var ha_muerto := false # Bandera para evitar que muera varias veces

func _ready():
	# Asegúrate de que el enemigo esté en el grupo correcto
	add_to_group("Enemigos") 
	animated_sprite.play("idle")

# --- Función llamada por la Bala ---
func morir():
	if ha_muerto: return # Si ya está muriendo, no hacer nada
	ha_muerto = true
	
	# Desactivamos la colisión para que no lo golpeen de nuevo
	colision.disabled = true
	
	# Reproducimos la animación de muerte
	animated_sprite.play("muerte") # Asegúrate de tener esta animación
	
	# Esperamos a que la animación termine
	await animated_sprite.animation_finished
	
	# Eliminamos al enemigo de la escena
	queue_free()

# --- Señal conectada a 'body_entered' ---
# Esto detecta si el Player toca al enemigo
func _on_body_entered(body: Node2D):
	# Comprueba si el cuerpo es el Player (debe estar en el grupo "Player")
	if body.is_in_group("Player"):
		print("¡Enemigo tocó al Player!")
		
		# Llama a la función 'morir_por_enemigo' en el Player
		if body.has_method("morir_por_enemigo"):
			body.morir_por_enemigo()
