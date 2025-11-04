# Moneda.gd
extends Area2D

# --- ¡CAMBIO AQUÍ! ---
# 1. Carga el archivo de sonido MP3
# (¡Asegúrate de que esta ruta y el nombre del archivo MP3 sean correctos!)
var SonidoMoneda = preload("res://Assets/SFX/nickelpickup.mp3") 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D

var _ya_recolectada: bool = false

func _ready():
	if animated_sprite:
		animated_sprite.play("default") 

func _on_body_entered(body: Node2D) -> void:
	if not _ya_recolectada and body is CharacterBody2D: 
		_ya_recolectada = true 

		if colision:
			colision.disabled = true
		
		# Llama a la función para reproducir el sonido
		_play_sound_effect()
		
		if animated_sprite:
			animated_sprite.visible = true 
			animated_sprite.play("pickup")
			await animated_sprite.animation_finished
		
		queue_free()

func _play_sound_effect():
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = SonidoMoneda
	audio_player.autoplay = true 
	audio_player.finished.connect(audio_player.queue_free)
	get_tree().root.add_child(audio_player)
