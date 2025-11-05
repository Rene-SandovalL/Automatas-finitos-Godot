# Enemigo.gd
extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D

var ha_muerto := false 

func _ready():
	# --- ¡Solución 2A! ---
	# Asegúrate de que el enemigo esté en el grupo "Enemigos"
	add_to_group("Enemigos") 
	animated_sprite.play("idle")

func morir():
	if ha_muerto: return 
	ha_muerto = true
	
	colision.disabled = true
	animated_sprite.play("muerte") 
	
	await animated_sprite.animation_finished
	queue_free()

# --- ¡Solución 2B! ---
# Esta función DEBE estar conectada a la señal 'body_entered'
func _on_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		print("¡Enemigo tocó al Player!")
		if body.has_method("morir_por_enemigo"):
			body.morir_por_enemigo()
