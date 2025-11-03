extends GPUParticles2D

# EfectoMoneda.gd
func _ready():
	# Inicia la emisión de partículas
	emitting = true

	# Espera a que todas las partículas terminen
	await finished

	# Autodestruye la escena de partículas
	queue_free()
