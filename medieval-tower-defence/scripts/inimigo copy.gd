extends CharacterBody2D

# --- ESTATÍSTICAS ---
@export var velocidade: float = 100.0
@export var vida: int = 30
@export var dano: int = 10
@export var intervalo_ataque: float = 1.0 # Ataca a cada 1 segundo

# --- REFERÊNCIAS VISUAIS ---
# Ajuste "Sprite2D" para o nome do seu nó de imagem (ex: AnimatedSprite2D)
@onready var sprite_visual = $Sprite2D 

# --- NAVEGAÇÃO & COMBATE ---
var pontos_do_caminho: Array[Vector2] = []
var indice_atual: int = 0
var alvo_final: Node2D
var tempo_recarga: float = 0.0

func _ready():
	# Garante movimento suave para top-down
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

func _physics_process(delta):
	# 1. Se a base foi destruída, o inimigo para
	if alvo_final == null: 
		velocity = Vector2.ZERO
		return

	# 2. Verifica a distância até a base
	var distancia = global_position.distance_to(alvo_final.global_position)
	
	# --- MÁQUINA DE ESTADOS SIMPLES ---
	if distancia < 50.0:
		# ESTADO: ATACANDO (Perto da base)
		velocity = Vector2.ZERO # Para de andar
		processar_ataque_continuo(delta)
	else:
		# ESTADO: ANDANDO (Longe da base)
		seguir_caminho()
		atualizar_orientacao() # Vira o sprite

func seguir_caminho():
	if pontos_do_caminho.is_empty():
		return 

	# Se ainda tem pontos na lista...
	if indice_atual < pontos_do_caminho.size():
		var destino = pontos_do_caminho[indice_atual]
		var direcao = global_position.direction_to(destino)
		
		velocity = direcao * velocidade
		move_and_slide()
		
		# Se chegou na esquina (4px de raio), mira na próxima
		if global_position.distance_to(destino) < 4.0:
			indice_atual += 1
	else:
		# Acabou o caminho mas não tá colado na base (failsafe)
		# Anda direto na direção da base
		var direcao = global_position.direction_to(alvo_final.global_position)
		velocity = direcao * velocidade
		move_and_slide()

func atualizar_orientacao():
	# Se tiver velocidade horizontal, vira o sprite
	if velocity.x != 0:
		# Se velocity.x < 0 (esquerda), flip_h = true.
		# Se velocity.x > 0 (direita), flip_h = false.
		if sprite_visual:
			sprite_visual.flip_h = velocity.x < 0

func processar_ataque_continuo(delta):
	# Diminui o contador
	tempo_recarga -= delta
	
	# Hora de bater?
	if tempo_recarga <= 0:
		atacar_base()
		tempo_recarga = intervalo_ataque # Reseta o timer (ex: 1.0s)

func atacar_base():
	if is_instance_valid(alvo_final) and alvo_final.has_method("receber_dano"):
		print("POW! Inimigo causou ", dano, " de dano.")
		alvo_final.receber_dano(dano)
		# O inimigo continua vivo batendo!

# --- CONFIGURAÇÃO (Chamado pelo Spawner) ---
func definir_rota(path_2d: Path2D, base_alvo: Node2D):
	alvo_final = base_alvo
	pontos_do_caminho = []
	indice_atual = 0
	
	if path_2d:
		var curva = path_2d.curve
		# Pega os pontos desenhados e converte para coordenadas do mundo
		for i in range(curva.point_count):
			pontos_do_caminho.append(path_2d.to_global(curva.get_point_position(i)))
