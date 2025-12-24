extends "res://Scripts/inimigo.gd"

var flecha_cena = preload("res://Scene/flecha.tscn")

# Sobrescrevemos o ataque corpo-a-corpo por tiro
func atacar(alvo):
	# Bloqueia novos ataques (copiando a logica do pai)
	pode_atacar = false
	timer_ataque.start()
	
	if anim_player.has_animation("atacando"):
		anim_player.play("atacando")
		
	# Lógica do TIRO
	var flecha = flecha_cena.instantiate()
	flecha.alvo_e_inimigo = false # Essa flecha mata ALIADOS (Player)
	flecha.global_position = global_position
	flecha.look_at(alvo.global_position)
	get_tree().root.add_child(flecha)
	
	print("Inimigo Arqueiro disparou!")
