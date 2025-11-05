# Enemigo.gd
extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D

var ha_muerto := false # Bandera para evitar doble muerte o animaciones extrañas

func _ready():
	add_to_group("Enemigos") # ¡IMPORTANTE! Añade al enemigo al grupo "Enemigos"
	animated_sprite.play("idle")

# --- Función llamada por la Bala cuando golpea al enemigo ---
func morir():
	if ha_muerto: return # Si ya está muriendo, no hacer nada
	ha_muerto = true
	
	print("¡Enemigo está muriendo!")
	colision.disabled = true # Desactiva la colisión para que no lo golpeen más
	animated_sprite.play("death") # ¡Asegúrate de que esta animación exista!
	
	await animated_sprite.animation_finished # Espera a que termine la animación
	
	queue_free() # Elimina al enemigo de la escena al finalizar la animación

# --- Función conectada a la señal 'body_entered' ---
# ¡IMPORTANTE! Conecta esta señal en el editor de Godot (nodo raíz Enemigo -> Pestaña Nodo -> Señales -> body_entered)
func _on_body_entered(body: Node2D):
	# Comprueba si el cuerpo que tocó está en el grupo "Player"
	if body.is_in_group("Player"):
		print("¡Enemigo tocó al Player!")
		# Llama a la función de muerte del Player si existe
		if body.has_method("morir_por_enemigo"):
			body.morir_por_enemigo()
