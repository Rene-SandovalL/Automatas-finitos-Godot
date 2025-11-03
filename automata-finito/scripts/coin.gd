# Moneda.gd
extends Area2D

# --- YA NO NECESITAMOS ESTA LÍNEA, LA ANIMACIÓN DE PARTÍCULAS ESTÁ EN EL SPRITE ---
# var ParticulaEfecto = preload("res://scenes/coineffect.tscn") 

@onready var animated_sprite: AnimatedSprite2D = $CoinSprite # Renombré a 'animated_sprite' para claridad
@onready var colision: CollisionShape2D = $CollisionShape2D

# Bandera para evitar que la moneda se active múltiples veces
var _ya_recolectada: bool = false


# --- Función que se llama cuando un cuerpo entra en el Area2D de la moneda ---
func _on_body_entered(body: Node2D) -> void:
	# Solo ejecuta la lógica si la moneda no ha sido recolectada ya
	# y si el cuerpo que entró es tu Player (CharacterBody2D)
	if not _ya_recolectada and body is CharacterBody2D: 
		_ya_recolectada = true # Marca la moneda como recolectada

		# --- ORDEN ESPECÍFICO SOLICITADO ---
		
		# 1. Desactiva la colisión inmediatamente
	
			# Hacmos visible el AnimatedSprite para que la animación 'pickup' se vea
		animated_sprite.play("pickup")
			
			# Espera a que la animación de "pickup" termine
		await animated_sprite.animation_finished
		
		# 4. Elimina la moneda de la escena una vez que la animación de "pickup" ha terminado
		queue_free()
