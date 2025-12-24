extends CharacterBody2D

# --- ESTATÍSTICAS ---
@export var velocidade: float = 100.0
@export var vida: int = 30
@export var dano: int = 10
@export var valor_em_ouro: int = 15

# --- REFERÊNCIAS ---
@onready var sprite_visual = $Sprite2D 
@onready var anim_player = $AnimationPlayer 
@onready var detector = $DetectorAtaque
@onready var timer_ataque = $TimerAtaque # <--- REFERÊNCIA AO TIMER
@onready var barra_vida = $ProgressBar

signal inimigo_morreu(valor)

# Variáveis de Navegação
var pontos_do_caminho: Array[Vector2] = [] 
var indice_atual: int = 0 
var alvo_final: Node2D 

# Controle de Ataque
var pode_atacar: bool = true # Começa podendo atacar

func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	
	# --- CONFIGURAÇÃO DA BARRA DE VIDA ---
	barra_vida.max_value = vida # A barra agora vai de 0 a 30
	barra_vida.value = vida     # Começa cheia
	barra_vida.show()           # Garante que está visível
	
	timer_ataque.timeout.connect(_on_timer_ataque_timeout)
	
	if anim_player.has_animation("correndo"):
		anim_player.play("correndo")

func _physics_process(_delta): # Não precisamos mais do delta aqui para o tempo
	if alvo_final == null: return

	# 1. TENTA ATACAR
	# Se encontrar algo para bater, ele para de andar (return true)
	if processar_combate():
		return 

	# 2. SE NÃO ESTIVER EM COMBATE, ANDA
	if anim_player.current_animation != "correndo":
		anim_player.play("correndo")
		
	mover_pela_rota()
	atualizar_orientacao()

func processar_combate() -> bool:
	# Pega tudo que está dentro da Area2D 'DetectorAtaque'
	var corpos = detector.get_overlapping_bodies()
	
	# DEBUG: Se quiser ver se ele está detectando ALGO (mesmo que seja chão)
	# if corpos.size() > 0:
	# 	print("Detector vendo: ", corpos)

	for corpo in corpos:
		# Ignora a si mesmo
		if corpo == self: continue
		
		# Ignora outros inimigos (para não bater no amigo da frente)
		if corpo is CharacterBody2D and corpo.name != "Base": 
			# Assumindo que a Base agora é StaticBody2D, então CharacterBody2D só pode ser inimigo
			continue

		# Se achou algo que tem vida (Tropa ou Base)
		if corpo.has_method("receber_dano"):
			
			# Para o movimento imediatamente
			velocity = Vector2.ZERO
			
			# Só bate se o Timer permitiu
			if pode_atacar:
				atacar(corpo)
			
			return true # Retorna verdadeiro: "Estou em combate!"
			
	return false # Ninguém por perto

func atacar(alvo):
	# 1. Bloqueia novos ataques
	pode_atacar = false
	
	# 2. Inicia o Timer (Vai liberar o ataque de novo daqui a 1 segundo)
	timer_ataque.start()
	
	# 3. Visual e Dano
	if anim_player.has_animation("atacando"):
		anim_player.play("atacando")
	
	print("POW! Inimigo bateu em: ", alvo.name)
	alvo.receber_dano(dano)

func _on_timer_ataque_timeout():
	# Quando o relógio apita, libera o ataque novamente
	pode_atacar = true

# --- MOVIMENTO (MANTIDO IGUAL) ---
func mover_pela_rota():
	if pontos_do_caminho.is_empty():
		velocity = global_position.direction_to(alvo_final.global_position) * velocidade
		move_and_slide()
		return

	if indice_atual < pontos_do_caminho.size():
		var destino = pontos_do_caminho[indice_atual]
		var direcao = global_position.direction_to(destino)
		velocity = direcao * velocidade
		move_and_slide()
		if global_position.distance_to(destino) < 10.0:
			indice_atual += 1
	else:
		var direcao = global_position.direction_to(alvo_final.global_position)
		velocity = direcao * velocidade
		move_and_slide()

# --- SETUP E VIDA ---
func atualizar_orientacao():
	if velocity.x != 0 and sprite_visual:
		sprite_visual.flip_h = velocity.x < 0

func definir_rota(path_2d: Path2D, base_alvo: Node2D):
	alvo_final = base_alvo
	pontos_do_caminho = []
	indice_atual = 0
	if path_2d:
		var curva = path_2d.curve
		for i in range(curva.point_count):
			pontos_do_caminho.append(path_2d.to_global(curva.get_point_position(i)))

func receber_dano(quantidade: int):
	vida -= quantidade
	
	# --- ATUALIZA A BARRA VISUALMENTE ---
	barra_vida.value = vida
	
	if vida <= 0:
		morrer()

func morrer():
	print("Inimigo derrotado!")
	inimigo_morreu.emit(valor_em_ouro)
	queue_free()
