extends "res://scripts/tropa_barreira.gd" 
var flecha_cena = preload("res://Scene/flecha.tscn")
@onready var ponto_disparo = $Marker2D 


func atacar(alvo):
	if is_instance_valid(alvo) and alvo is Node2D:
		_virar_para_posicao(alvo.global_position)
	if anim_player.has_animation("atacando"):
		anim_player.play("atacando")
	
	var flecha = flecha_cena.instantiate()
	
	flecha.alvo_e_inimigo = true 
	flecha.global_position = global_position 
	flecha.look_at(alvo.global_position)
	
	get_tree().root.add_child(flecha)
	
	print("Arqueiro disparou flecha!")
