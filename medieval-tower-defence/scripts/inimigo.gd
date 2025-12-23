extends CharacterBody2D

# --- ESTATÍSTICAS DO INIMIGO ---
@export var velocidade: float = 100.0
@export var vida: int = 30
@export var dano: int = 10
@export var valor_em_ouro: int = 15 # Quanto o player ganha ao matar

# Essa função será chamada pelo jogo quando a Barreira ou Torre acertar ele
func receber_dano(quantidade: int):
	vida -= quantidade
	# Podemos piscar vermelho aqui depois (efeito visual)
	print("Inimigo tomou dano! Vida: ", vida)
	
	if vida <= 0:
		morrer()

func morrer():
	# Aqui vamos dar dinheiro ao player no futuro
	print("Goblin morreu! +", valor_em_ouro, " de ouro.")
	queue_free() # Some do mapa
