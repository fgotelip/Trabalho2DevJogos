class_name Entidade extends Area2D

@export var vida_maxima: int = 100
var vida_atual: int

func _ready():
	vida_atual = vida_maxima

func receber_dano(quantidade: int):
	vida_atual -= quantidade
	print(name, " tomou ", quantidade, " de dano. Vida: ", vida_atual)

	if vida_atual <= 0:
		morrer()

func morrer():
	queue_free()
