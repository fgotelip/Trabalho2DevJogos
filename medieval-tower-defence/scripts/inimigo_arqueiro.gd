extends "res://scripts/inimigo.gd"

var flecha_cena = preload("res://Scene/flecha.tscn")
@onready var shape_ataque = $DetectorAtaque/CollisionShape2D 
# Sobrescrevemos o ataque corpo-a-corpo por tiro
func atacar(alvo):
	# Bloqueia novos ataques (copiando a logica do pai)
	pode_atacar = false
	timer_ataque.start()

	if is_instance_valid(alvo) and alvo is Node2D:
		_virar_para_posicao(alvo.global_position)
	
	if anim_player.has_animation("atacando"):
		anim_player.play("atacando")
		
	# Lógica do TIRO
	var flecha = flecha_cena.instantiate()
	flecha.alvo_e_inimigo = false # Essa flecha mata ALIADOS (Player)
	flecha.global_position = global_position
	flecha.look_at(alvo.global_position)
	get_tree().root.add_child(flecha)
	
	print("Inimigo Arqueiro disparou!")

func atualizar_orientacao():
	# Mantive a lógica original do Sprite
	if velocity.x != 0 and sprite_visual:
		sprite_visual.flip_h = velocity.x < 0

	# ADICIONADO: Lógica da rotação do ataque
	if shape_ataque:
		# Se a velocidade Vertical for maior que a Horizontal (está subindo/descendo)
		if abs(velocity.y) > abs(velocity.x):
			shape_ataque.rotation_degrees = 90 # Gira o retângulo
		
		# Se a velocidade Horizontal for maior (está indo para os lados)
		elif abs(velocity.x) > abs(velocity.y) and velocity.x != 0:
			shape_ataque.rotation_degrees = 0  # Volta o retângulo ao normal
