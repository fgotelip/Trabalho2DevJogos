extends StaticBody2D

signal base_destruida 

@export var vida_maxima: int = 100 

var vida_atual: int
@onready var barra_vida = $ProgressBar

func _ready(): 
	vida_atual = vida_maxima
	print("Base iniciada. Vida: ", vida_atual)
	if barra_vida:
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_atual

func receber_dano(quantidade: int):
	vida_atual -= quantidade

	if barra_vida:
		barra_vida.value = vida_atual
	print("ALERTA: Base sob ataque! Vida restante: ", vida_atual)
	
	if vida_atual <= 0:
		morrer()

func morrer():
	print("GAME OVER - A Base caiu!")
	base_destruida.emit()
	visible = false 
