extends CharacterBody2D

asd@export var speed = 100.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

var last_direction = "down"

func _physics_process(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	
	if input_direction.length() > 0:
		velocity = input_direction.normalized() * speed
	else:
		velocity = Vector2.ZERO 

	move_and_slide()
	
	update_animation(input_direction)

func update_animation(input_direction):
	if input_direction.length() > 0:
		if input_direction.x < 0:
			last_direction = "left"
		elif input_direction.x > 0:
			last_direction = "right"
		elif input_direction.y < 0:
			last_direction = "up"
		elif input_direction.y > 0:
			last_direction = "down"
		
		animated_sprite.play("walk_" + last_direction)
	else:
		animated_sprite.play("idle")
