extends StaticBody2D

signal base_destruida # Avisa o GameManager que perdemos

@export var vida_maxima: int = 100 

var vida_atual: int

# Referência à barra (garanta que o nó se chama ProgressBar na cena)
@onready var barra_vida = $ProgressBar

func _ready(): 
	vida_atual = vida_maxima
	print("Base iniciada. Vida: ", vida_atual)
	
	# Configura a barra visual
	if barra_vida:
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_atual
		
		# Opcional: Personalizar a barra via código se não fez no editor
		# barra_vida.modulate = Color.GREEN 

func receber_dano(quantidade: int):
	vida_atual -= quantidade
	
	# Atualiza a barra visualmente
	if barra_vida:
		barra_vida.value = vida_atual
	
	print("ALERTA: Base sob ataque! Vida restante: ", vida_atual)
	
	if vida_atual <= 0:
		morrer()

func morrer():
	print("GAME OVER - A Base caiu!")
	base_destruida.emit()
	
	# Não usamos queue_free() imediatamente na base para não sumir o castelo
	# e dar erro no jogo, geralmente mostramos uma tela de Game Over antes.
	# Mas para teste, podemos esconder o sprite:
	visible = false 
	# queue_free() # Cuidado: se deletar a base, os inimigos perdem o alvo e o jogo pode travar.
