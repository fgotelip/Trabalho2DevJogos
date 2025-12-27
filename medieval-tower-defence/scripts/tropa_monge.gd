extends StaticBody2D

# --- CONFIGURAÇÕES ---
@export var vida_maxima: int = 100
@export var poder_cura: int = 20
@export var intervalo_cura: float = 1.5

# --- ESTADO ---
var pode_curar: bool = true
var vida_atual: int
var olhando_para_direita: bool = true

# --- REFERÊNCIAS ---
@onready var radar = $ShapeCast2D 
@onready var timer_cura = $Timer
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
	timer_cura.wait_time = intervalo_cura
	timer_cura.one_shot = true
	if not timer_cura.timeout.is_connected(_on_cooldown_acabou):
		timer_cura.timeout.connect(_on_cooldown_acabou)
	
	# Configurações do Radar
	radar.target_position = Vector2.ZERO 
	radar.enabled = true 
	radar.max_results = 10 # Define quantos aliados no MÁXIMO ele pode curar de uma vez
	olhando_para_direita = (scale.x >= 0)

func _physics_process(_delta):
	if pode_curar:
		escanear_e_curar_area()

func escanear_e_curar_area():
	# 1. Atualiza o radar
	radar.force_shapecast_update()
	
	if not radar.is_colliding():
		return # Ninguém por perto

	# 2. Variável de controle (Flag)
	# Começa falsa. Se curarmos pelo menos UM, ela vira verdadeira.
	var curou_alguem: bool = false
	
	# 3. Loop por TODOS os contatos
	var total_encontrados = radar.get_collision_count()
	
	for i in range(total_encontrados):
		var aliado = radar.get_collider(i)
		
		# Validações de segurança
		if not is_instance_valid(aliado): continue
		if aliado.name == "Base": continue # Não cura a base (opcional)
		
		# Verifica se precisa de cura
		if aliado.has_method("receber_dano"):
			if aliado.vida_atual < aliado.vida_maxima:
				# Vira para quem vai curar
				_virar_para_posicao(aliado.global_position)
				
				# --- APLICAÇÃO DA CURA ---
				# Curamos direto aqui, sem 'return'
				aliado.receber_dano(-poder_cura)
				print("Monge curou: ", aliado.name)
				
				# Marcamos que houve atividade útil
				curou_alguem = true
	
	# 4. Pós-Processamento
	# Se pelo menos uma pessoa foi curada, ativamos o cooldown
	if curou_alguem:
		iniciar_recarga()

func iniciar_recarga():
	pode_curar = false
	
	if anim_player.has_animation("curando"):
		anim_player.play("curando")
	
	timer_cura.start()

func _on_cooldown_acabou():
	pode_curar = true
	if anim_player.has_animation("idle"):
		anim_player.play("idle")

func _virar_para_posicao(pos: Vector2):
	var dx = pos.x - global_position.x
	if abs(dx) < 0.001:
		return
	olhando_para_direita = dx > 0.0
	scale.x = abs(scale.x) if olhando_para_direita else -abs(scale.x)

# --- LÓGICA DE VIDA DO PRÓPRIO MONGE ---
func receber_dano(quantidade: int):
	vida_atual -= quantidade
	if vida_atual > vida_maxima: vida_atual = vida_maxima
	
	if barra_vida: barra_vida.value = vida_atual
	
	if vida_atual <= 0:
		morrer()

func morrer():
	queue_free()
