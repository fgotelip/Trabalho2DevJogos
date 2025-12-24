extends CharacterBody2D

# --- ESTATÍSTICAS ---
@export var velocidade: float = 100.0
@export var vida: int = 30
@export var dano: int = 10
@export var valor_em_ouro: int = 15
@export var intervalo_ataque: float = 1.0 # Ataca a cada 1 segundo

@onready var sprite_visual = $Sprite2D 

# --- NAVEGAÇÃO ---
var pontos_do_caminho: Array[Vector2] = [] # Lista de esquinas para virar
var indice_atual: int = 0 # Em qual ponto da lista estamos indo agora?
var alvo_final: Node2D # A referência da Base
var tempo_recarga: float = 0.0

func _ready():
	# Garante que ele não sofra atrito desnecessário
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

func _physics_process(delta):
	# 1. SEGURANÇA: Se a base sumiu (foi destruída), para tudo.
	if alvo_final == null: 
		return

	atualizar_orientacao()

	# 3. Se não tem rota configurada, não anda.
	if pontos_do_caminho.is_empty():
		return

	# 4. Movimentação Ponto a Ponto
	# Se ainda temos pontos para visitar na lista...
	if indice_atual < pontos_do_caminho.size():
		var destino = pontos_do_caminho[indice_atual]
		var direcao = global_position.direction_to(destino)
		
		velocity = direcao * velocidade
		move_and_slide()
		
		# Verifica se chegou na esquina atual (raio de 4 pixels)
		if global_position.distance_to(destino) < 4.0:
			indice_atual += 1 # Mira no próximo ponto
	else:
		atacar_base(delta)

func atualizar_orientacao():
	# Se tiver velocidade horizontal, vira o sprite
	if velocity.x != 0:
		# Se velocity.x < 0 (esquerda), flip_h = true.
		# Se velocity.x > 0 (direita), flip_h = false.
		if sprite_visual:
			sprite_visual.flip_h = velocity.x < 0

func atacar_base(delta):
	tempo_recarga -= delta
	
	# Hora de bater?
	if tempo_recarga <= 0:
		if is_instance_valid(alvo_final) and alvo_final.has_method("receber_dano"):
			print("Inimigo causou ", dano, " de dano na Base!")
			alvo_final.receber_dano(dano) # Chama a função do script da Base
		tempo_recarga = intervalo_ataque # Reseta o timer (ex: 1.0s)
	# Verifica se a base ainda existe e tem vida
	
		
		# Efeito visual (opcional)
		# criar_explosao() 

# --- CONFIGURAÇÃO (Chamado pelo Spawner/Main) ---
func definir_rota(path_2d: Path2D, base_alvo: Node2D):
	alvo_final = base_alvo
	pontos_do_caminho = []
	indice_atual = 0
	
	if path_2d == null:
		print("ERRO: O Path2D não foi passado para o inimigo!")
		return

	# Pega APENAS os pontos de controle (as bolinhas que você clicou no editor)
	var curva = path_2d.curve
	for i in range(curva.point_count):
		# Converte de Local (Path2D) para Global (Mundo)
		var ponto_global = path_2d.to_global(curva.get_point_position(i))
		pontos_do_caminho.append(ponto_global)
	
	print("Rota definida com ", pontos_do_caminho.size(), " pontos.")
	
# --- ADICIONE ISSO NO FINAL DO SCRIPT DO INIMIGO ---
