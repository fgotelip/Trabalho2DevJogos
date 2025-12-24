extends Area2D

signal base_destruida # criamos um sinal que será emitido quando a base for destruida para gerenciar o que vai acontecer

@export var vida_maxima: int = 100 # export permite editar a vida no inspetor e, por conseuqencia, poder ter vidas diferentes para copias diferentes dessa mesma cena

var vida_atual: int

func _ready(): # assim que a instacia do objeto é criada ele é executado
	vida_atual = vida_maxima
	print("Base instaciada, vida atual:",vida_atual)


func morrer():
	print("Game Over")

	base_destruida.emit()

	queue_free()

func checar_vida():
	if vida_atual <= 0:
		morrer()

func receber_dano(dano: int):
	vida_atual -= dano
	print("Dano recebido, vida atual:",vida_atual)

	checar_vida()


func _process(delta): # executada o tempo todo -> delta serve para igualar computadores diferentes
	if Input.is_action_just_pressed("ui_accept"): # apenas um clique
		receber_dano(20)
