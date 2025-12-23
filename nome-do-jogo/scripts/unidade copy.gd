class_name Unidade extends Area2D

# --- CONFIGURAÇÕES (O que muda de um para o outro) ---
@export_group("Estatísticas")
@export var vida_maxima: int = 100
@export var velocidade: int = 100
@export var dano: int = 10
@export var cadencia_ataque: float = 1.0 # Tempo em segundos entre ataques

@export_group("Comportamento")
# Aqui está a mágica: Você escreve no Inspector quem ele odeia.
# Ex: Tropa escreve ["inimigos", "estruturas_inimigas"]
# Ex: Inimigo escreve ["tropas", "base"]
@export var grupos_alvo: Array[String] = []

# --- VARIÁVEIS INTERNAS ---
var vida_atual: int
var alvo_atual: Node2D = null
var pode_atacar: bool = true

# Referências aos nós filhos (precisa ter um nó chamado Detector e um Timer)
@onready var timer_ataque = $Timer

func _ready():
	vida_atual = vida_maxima
	
	# Configura o Timer com a cadência definida
	timer_ataque.wait_time = cadencia_ataque
	timer_ataque.one_shot = true # Ele roda uma vez e para, até mandarmos rodar de novo
	
	# Se for inimigo, adiciona ao grupo inimigos, etc.
	# (Isso você pode configurar no nó raiz, ou fazer uma lógica aqui)

func _process(delta):
	# MÁQUINA DE ESTADOS SIMPLIFICADA
	
	if alvo_atual != null and is_instance_valid(alvo_atual):
		# Temos um alvo. Estamos no alcance de ataque?
		# A verificação de alcance é feita pelo DETECTOR (sinais).
		# Se o alvo ainda está na lista do detector, paramos e atacamos.
		if pode_atacar:
			atacar()
	else:
		# Sem alvo de ataque, precisamos andar.
		# AQUI entra a lógica de movimento.
		# Se for Tropa: Anda para a direita (+X) ou para um ponto específico.
		# Se for Inimigo: Anda para a esquerda (-X) ou para a Base.
		comportamento_movimento(delta)

# Função para ser sobrescrita ou configurada
func comportamento_movimento(delta):
	# Exemplo simples: Anda sempre em frente baseando-se na rotação ou direção padrão
	# Você pode melhorar isso depois passando um "Destino" global.
	pass 

# --- LÓGICA DE COMBATE ---

func atacar():
	print(name, " atacou ", alvo_atual.name)
	
	if alvo_atual.has_method("receber_dano"):
		alvo_atual.receber_dano(dano)
	
	# Inicia o Cooldown
	pode_atacar = false
	timer_ataque.start()

# Chamado automaticamente quando o Timer acaba
func _on_timer_timeout():
	pode_atacar = true

# --- SISTEMA DE DETECÇÃO (O Alcance) ---
# Conecte o sinal `area_entered` do nó DETECTOR (não da raiz) aqui
func _on_detector_area_entered(area):
	# Verifica se a área que entrou faz parte de algum grupo que odiamos
	for grupo in grupos_alvo:
		if area.is_in_group(grupo):
			alvo_atual = area
			print("Alvo detectado: ", area.name)
			return # Achou um alvo, para de procurar

# Conecte o sinal `area_exited` do nó DETECTOR aqui
func _on_detector_area_exited(area):
	if area == alvo_atual:
		alvo_atual = null
		print("Alvo saiu do alcance.")

# --- LÓGICA DE VIDA ---
func receber_dano(quantidade):
	vida_atual -= quantidade
	if vida_atual <= 0:
		queue_free()