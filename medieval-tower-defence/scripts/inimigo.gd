extends CharacterBody2D

@export_group("Atributos")
@export var velocidade: float = 100.0
@export var vida: int = 40
@export var dano: int = 8
@export var valor_em_ouro: int = 15
@export var intervalo_ataque: float = 1.0

@onready var sprite_visual = $Sprite2D 
@onready var anim_player = $AnimationPlayer 
@onready var detector = $DetectorAtaque
@onready var timer_ataque = $TimerAtaque
@onready var barra_vida = $ProgressBar

signal inimigo_morreu(valor)

var pontos_do_caminho: Array[Vector2] = [] 
var indice_atual: int = 0 
var alvo_final: Node2D 
var explosao_cena = preload("res://Scene/explosao.tscn")

var pode_atacar: bool = true 
var olhando_para_direita: bool = true
var alvo_pendente_dano: Node2D = null

func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	
	if get_node_or_null("/root/Global"):
		vida = int(vida * Global.multiplicador_vida)
		dano = int(dano * Global.multiplicador_dano)
		print("Dificuldade aplicada. Vida: ", vida, " Dano: ", dano)
	
	olhando_para_direita = (sprite_visual == null or not sprite_visual.flip_h)
	
	if anim_player and not anim_player.animation_finished.is_connected(_on_animation_finished):
		anim_player.animation_finished.connect(_on_animation_finished)
	
	if barra_vida:
		barra_vida.max_value = vida
		barra_vida.value = vida
		barra_vida.show()
	
	timer_ataque.wait_time = intervalo_ataque
	timer_ataque.timeout.connect(_on_timer_ataque_timeout)

	tocar_animacao("idle") 

func _physics_process(_delta):
	if alvo_final == null: return

	if processar_combate():
		return 

	mover_pela_rota()
	atualizar_orientacao()

func tocar_animacao(nome: String):
	if anim_player.has_animation(nome):
		if anim_player.current_animation != nome:
			anim_player.play(nome)

func processar_combate() -> bool:
	var corpos = detector.get_overlapping_bodies()
	
	for corpo in corpos:
		if corpo == self: continue
		
		if corpo is CharacterBody2D and corpo.name != "Base": 
			continue

		if corpo.has_method("receber_dano"):
			velocity = Vector2.ZERO
			
			if corpo is Node2D:
				_virar_para_posicao(corpo.global_position)
			
			if pode_atacar:
				atacar(corpo)
			else:

				if anim_player.current_animation != "atacando":
					tocar_animacao("idle")
			
			return true 
			
	return false

func atacar(alvo):
	pode_atacar = false
	timer_ataque.start()
	alvo_pendente_dano = alvo
	tocar_animacao("atacando")

func _on_animation_finished(anim_name):
	if anim_name == "atacando":
		if is_instance_valid(alvo_pendente_dano) and alvo_pendente_dano.has_method("receber_dano"):
			alvo_pendente_dano.receber_dano(dano)
		
		alvo_pendente_dano = null
		tocar_animacao("idle")

func _on_timer_ataque_timeout():
	pode_atacar = true

func mover_pela_rota():
	var direcao = Vector2.ZERO
	
	if pontos_do_caminho.is_empty():
		direcao = global_position.direction_to(alvo_final.global_position)
	elif indice_atual < pontos_do_caminho.size():
		var destino = pontos_do_caminho[indice_atual]
		direcao = global_position.direction_to(destino)
		if global_position.distance_to(destino) < 10.0:
			indice_atual += 1
	else:
		direcao = global_position.direction_to(alvo_final.global_position)

	velocity = direcao * velocidade

	var posicao_antes = global_position
	move_and_slide()
	var distancia_percorrida = global_position.distance_to(posicao_antes)
	
	if distancia_percorrida > 0.6:
		tocar_animacao("correndo")
	else:
		tocar_animacao("idle")

func atualizar_orientacao():
	if velocity.x != 0 and sprite_visual:
		sprite_visual.flip_h = velocity.x < 0
		olhando_para_direita = not sprite_visual.flip_h

func _virar_para_posicao(pos: Vector2):
	var dx = pos.x - global_position.x
	if abs(dx) < 0.001:
		return
	var nova_direita = dx > 0.0
	if sprite_visual:
		sprite_visual.flip_h = not nova_direita
	olhando_para_direita = nova_direita

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
	
	if barra_vida:
		barra_vida.value = vida
		
	if vida <= 0:
		morrer()

func morrer():
	var efeito = explosao_cena.instantiate()
	efeito.global_position = global_position 
	
	get_tree().root.add_child(efeito)
	
	inimigo_morreu.emit(valor_em_ouro)
	queue_free()
