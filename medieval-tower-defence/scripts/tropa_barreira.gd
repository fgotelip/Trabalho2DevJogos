extends StaticBody2D

# --- ESTATÍSTICAS ---
@export_group("Atributos")
@export var vida_maxima: int = 100
@export var dano: int = 10
@export var intervalo_ataque: float = 1.0

var vida_atual: int
var inimigos_no_alcance: Array = [] 
var esta_a_atacar: bool = false # <--- O SEGREDO DO ESTADO
var olhando_para_direita: bool = true
var alvo_pendente_dano: Node2D = null

# --- REFERÊNCIAS ---
@onready var timer_ataque = $Timer 
@onready var area_alcance = $AreaAlcance 
@onready var anim_player = $AnimationPlayer 
@onready var barra_vida = $ProgressBar

func _ready():
	vida_atual = vida_maxima
	
	# Configura Barra de Vida
	if barra_vida:
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_atual
		barra_vida.show()
	
	# Configura Timer
	timer_ataque.wait_time = intervalo_ataque
	timer_ataque.timeout.connect(_on_timer_timeout)
	
	# Conecta Sinais de Visão
	if not area_alcance.body_entered.is_connected(_on_inimigo_entrou):
		area_alcance.body_entered.connect(_on_inimigo_entrou)
	if not area_alcance.body_exited.is_connected(_on_inimigo_saiu):
		area_alcance.body_exited.connect(_on_inimigo_saiu)
	
	# --- CONEXÃO IMPORTANTE: FIM DA ANIMAÇÃO ---
	# Avisa-me quando qualquer animação terminar
	if not anim_player.animation_finished.is_connected(_on_animation_finished):
		anim_player.animation_finished.connect(_on_animation_finished)
		
	# Estado Inicial
	tocar_animacao("idle")
	# Garante orientação inicial
	olhando_para_direita = (scale.x >= 0)

func _virar_para_posicao(pos: Vector2):
	var dx = pos.x - global_position.x
	if abs(dx) < 0.001:
		return
	var nova_direita = dx > 0.0
	if nova_direita != olhando_para_direita:
		olhando_para_direita = nova_direita
		scale.x = abs(scale.x) if olhando_para_direita else -abs(scale.x)

# --- GERENCIADOR DE ANIMAÇÃO ---
func tocar_animacao(nome: String):
	if anim_player.has_animation(nome):
		anim_player.play(nome)

func _on_animation_finished(anim_name):
	# Se acabou o ataque (ou cura), liberta o personagem e volta a Idle
	if anim_name == "atacando":
		# Aplica dano somente ao final da animação
		if is_instance_valid(alvo_pendente_dano) and alvo_pendente_dano.has_method("receber_dano"):
			alvo_pendente_dano.receber_dano(dano)
		alvo_pendente_dano = null
		esta_a_atacar = false
		tocar_animacao("parado")
	elif anim_name == "curando":
		esta_a_atacar = false
		tocar_animacao("parado")

# --- COMBATE ---
func atacar(alvo):
	# Se já está ocupado a atacar, ignora (evita reiniciar animação)
	if esta_a_atacar:
		return

	# Vira para o alvo antes de atacar
	if is_instance_valid(alvo) and alvo is Node2D:
		_virar_para_posicao(alvo.global_position)
		
	# Bloqueia novas ações
	esta_a_atacar = true
	alvo_pendente_dano = alvo
	
	tocar_animacao("atacando")
	print("Tropa atacou: ", alvo.name)

func _on_timer_timeout():
	# Limpeza da lista
	inimigos_no_alcance = inimigos_no_alcance.filter(func(i): return is_instance_valid(i))
	
	if inimigos_no_alcance.size() > 0:
		# Só tenta atacar se não estiver já a meio de um ataque
		if not esta_a_atacar:
			atacar(inimigos_no_alcance[0])
	else:
		timer_ataque.stop()

# --- DETECÇÃO ---
func _on_inimigo_entrou(body):
	if body.has_method("receber_dano") and body.name != "Base":
		inimigos_no_alcance.append(body)
		if timer_ataque.is_stopped():
			timer_ataque.start()
			# Tenta atacar imediatamente se estiver livre
			if not esta_a_atacar:
				_on_timer_timeout()

func _on_inimigo_saiu(body):
	if body in inimigos_no_alcance:
		inimigos_no_alcance.erase(body)
	if inimigos_no_alcance.is_empty():
		timer_ataque.stop()

# --- VIDA ---
func receber_dano(quantidade: int):
	vida_atual -= quantidade
	if vida_atual > vida_maxima: vida_atual = vida_maxima # Limite de cura
	
	if barra_vida: barra_vida.value = vida_atual
	
	if vida_atual <= 0:
		morrer()

func morrer():
	queue_free()
