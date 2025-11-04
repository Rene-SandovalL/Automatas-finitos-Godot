extends Area2D

var SonidoMoneda = preload("res://Assets/SFX/nickelpickup.mp3") 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var colision: CollisionShape2D = $CollisionShape2D

@onready var game_node = get_tree().root.get_node("Game")

var _ya_recolectada: bool = false

func _ready():
	if animated_sprite:
		animated_sprite.play("default") 

func _on_body_entered(body: Node2D) -> void:
	if not _ya_recolectada and body is CharacterBody2D: 
		_ya_recolectada = true 

		if colision:
			colision.disabled = true
		
		if game_node:
			game_node.add_score(1)
		else:
			print("¡ERROR en Moneda.gd! No se encontró el nodo 'Game'.")

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
