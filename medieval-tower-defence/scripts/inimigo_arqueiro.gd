extends "res://scripts/inimigo.gd"

var flecha_cena = preload("res://Scene/flecha.tscn")
@onready var shape_ataque = $DetectorAtaque/CollisionShape2D 
func atacar(alvo):
	pode_atacar = false
	timer_ataque.start()

	if is_instance_valid(alvo) and alvo is Node2D:
		_virar_para_posicao(alvo.global_position)
	
	if anim_player.has_animation("atacando"):
		anim_player.play("atacando")
		
	var flecha = flecha_cena.instantiate()
	flecha.alvo_e_inimigo = false
	flecha.global_position = global_position
	flecha.look_at(alvo.global_position)
	get_tree().root.add_child(flecha)
	
	print("Inimigo Arqueiro disparou!")

func atualizar_orientacao():
	if velocity.x != 0 and sprite_visual:
		sprite_visual.flip_h = velocity.x < 0

	if shape_ataque:
		if abs(velocity.y) > abs(velocity.x):
			shape_ataque.rotation_degrees = 90 

		elif abs(velocity.x) > abs(velocity.y) and velocity.x != 0:
			shape_ataque.rotation_degrees = 0  
