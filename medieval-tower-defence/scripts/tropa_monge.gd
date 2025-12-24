extends "res://Scripts/tropa_barreira.gd"

func _ready():
	super._ready()
	dano = -20 # Valor negativo cura

func _on_inimigo_entrou(body):
	# Filtra aliados (Máscara 3 deve estar ativa no editor)
	if body != self and body.has_method("receber_dano"):
		inimigos_no_alcance.append(body)
		if timer_ataque.is_stopped():
			timer_ataque.start()
			if not esta_a_atacar:
				_on_timer_timeout()

# Sobrescrevemos o ataque para verificar se precisa de cura
func atacar(alvo):
	# 1. Se já está a animar, aborta
	if esta_a_atacar:
		return

	# 2. Se a vida já está cheia, não gasta "mana" nem animação
	if alvo.vida_atual >= alvo.vida_maxima:
		return 

	# 3. Inicia processo de cura
	esta_a_atacar = true
	tocar_animacao("curando") # Certifique-se que o nome da animação é "curando"
	
	print("Monge curou: ", alvo.name)
	alvo.receber_dano(dano)
