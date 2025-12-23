extends Camera2D

@export var velocidade : float

func _process(delta: float) -> void:
	#Definição da movimentação da câmera, definir os limites após montar o mapa
	var dx =  Input.get_axis("Esquerda","Direita")
	var dy =  Input.get_axis("Cima","Baixo")
	dx = dx*velocidade*delta
	dy = dy*velocidade*delta
	translate(Vector2(dx,dy))
