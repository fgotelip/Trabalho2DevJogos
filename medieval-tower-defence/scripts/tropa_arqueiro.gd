extends "res://Scripts/tropa_barreira.gd" 
# ^^^ ISSO É HERANÇA! Pegamos tudo do script anterior.

# Carregamos a flecha
var flecha_cena = preload("res://Scene/flecha.tscn")
@onready var ponto_disparo = $Marker2D # Opcional: crie um Marker2D na ponta do arco

# Sobrescrevemos (Override) a função atacar
func atacar(alvo):
	# 1. Toca animação (se tiver)
	if anim_player.has_animation("atacando"):
		anim_player.play("atacando")
	
	# 2. Cria a flecha
	var flecha = flecha_cena.instantiate()
	
	# 3. Configura a flecha
	flecha.alvo_e_inimigo = true # Essa flecha mata inimigos
	
	# Posição de saída
	flecha.global_position = global_position 
	# Se criou o Marker2D: flecha.global_position = ponto_disparo.global_position
	
	# 4. Mira no alvo
	flecha.look_at(alvo.global_position)
	
	# 5. Adiciona no mundo (não adicione como filho do arqueiro, senão a flecha gira com ele)
	get_tree().root.add_child(flecha)
	
	print("Arqueiro disparou flecha!")
