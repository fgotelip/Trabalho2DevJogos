extends Node2D

# --- REFERÊNCIAS ---
@onready var tile_map = $Camada_Chao 
@onready var ui = $InterfaceUsuario 
@onready var label_ouro = $InterfaceUsuario/LabelOuro 
@onready var label_orda = $InterfaceUsuario/LabelOrda
@onready var label_timer = $InterfaceUsuario/LabelTimer
@onready var rotas = $Rotas.get_children() 
#@onready var rotas = [$Rotas/Rota11]
@onready var base = $Base

# --- ECONOMIA ---
var custo_guerreiro: int = 100
var custo_arqueiro: int = 150
var custo_monge: int = 500
var ouro_atual: int = 10000000000 

# --- CENAS (ALIADOS E INIMIGOS) ---
var tropa_guerreiro_cena = preload("res://Scene/tropa_barreira.tscn") 
var tropa_arqueiro_cena = preload("res://Scene/tropa_arqueiro.tscn")
var tropa_monge_cena = preload("res://Scene/tropa_monge.tscn")

# INIMIGOS
var inimigo_guerreiro_cena = preload("res://Scene/character_body_2d.tscn") 
var inimigo_arqueiro_cena = preload("res://Scene/inimigo_arqueiro.tscn") # Certifique-se que criou esta cena!

# --- CONTROLE ---
var tropa_para_construir = null 
var custo_da_tropa_selecionada: int = 0
var sprite_preview = null 
var preview_facing_right: bool = true
var segurando_esq: bool = false
var tempo_hold: float = 0.0
const INTERVALO_HOLD: float = 0.2

# --- SISTEMA DE ORDAS ---
var orda_atual: int = 0
var inimigos_vivos: int = 0
var spawns_agendados: Array = []
var tempo_orda: float = 0.0
var aguardando_proxima_orda: bool = false
var tempo_espera_orda: float = 0.0
@export var duracao_orda: float = 75.0  # 1min 15seg
@export var delay_entre_ordas: float = 15.0
@export var total_ordas: int = 4
@export var faixas_inimigos_por_orda: Array[Vector2i] = [
	Vector2i(1, 3),
	Vector2i(3, 5),
	Vector2i(5, 7),
	Vector2i(9, 11)
]
@export var chance_arqueiro_por_orda: Array[float] = [0.5, 0.6, 0.6, 0.7]

func _ready():
	atualizar_interface_ouro()
	atualizar_interface_orda()
	iniciar_proxima_orda()

func _process(_delta):
	# Teclas de Atalho de Compra
	if Input.is_action_just_pressed("selecionar_tropa_1"): selecionar_guerreiro()
	elif Input.is_action_just_pressed("selecionar_tropa_2"): selecionar_arqueiro()
	elif Input.is_action_just_pressed("selecionar_tropa_3"): selecionar_monge()

	# Sistema de ordas
	if aguardando_proxima_orda:
		tempo_espera_orda -= _delta
		atualizar_interface_timer(tempo_espera_orda, true)
		if tempo_espera_orda <= 0.0:
			iniciar_proxima_orda()
	else:
		processar_orda(_delta)
		atualizar_interface_timer(duracao_orda - tempo_orda, false)

	if tropa_para_construir != null:
		atualizar_preview()
		# Construção contínua enquanto segura botão esquerdo
		if segurando_esq:
			tempo_hold -= _delta
			if tempo_hold <= 0.0:
				tentar_construir(preview_facing_right)
				tempo_hold = INTERVALO_HOLD

	# ESC para cancelar construção
	if Input.is_action_just_pressed("ui_cancel") and tropa_para_construir != null:
		cancelar_construcao()

# --- SISTEMA DE ORDAS ---
func iniciar_proxima_orda():
	orda_atual += 1
	if orda_atual > total_ordas:
		print("Todas as ordas completadas!")
		return
	
	aguardando_proxima_orda = false
	tempo_orda = 0.0
	spawns_agendados.clear()
	
	print("Iniciando Orda ", orda_atual)
	atualizar_interface_orda()
	
	# Configura parâmetros da orda (por rota)
	var idx_orda: int = max(orda_atual - 1, 0)
	var faixa_default: Vector2i = Vector2i(3, 5)
	var chance_default: float = 0.5
	var faixa_orda: Vector2i = faixas_inimigos_por_orda[idx_orda] if idx_orda < faixas_inimigos_por_orda.size() else faixa_default
	var chance_arqueiro: float = chance_arqueiro_por_orda[idx_orda] if idx_orda < chance_arqueiro_por_orda.size() else chance_default
	
	# Agenda spawns para cada rota
	for rota in rotas:
		var num_inimigos_nesta_rota = randi_range(faixa_orda.x, faixa_orda.y)
		
		# Gera tempos aleatórios para esta rota
		var tempos_spawn_rota: Array = []
		for _i in range(num_inimigos_nesta_rota):
			var tempo_aleatorio = randf_range(1.0, duracao_orda - 1.0)
			tempos_spawn_rota.append(tempo_aleatorio)
		
		# Ordena os tempos para spawnar em ordem crescente
		tempos_spawn_rota.sort()
		
		# Cria os spawns agendados
		for tempo_spawn in tempos_spawn_rota:
			# Escolhe tipo de inimigo
			var cena_inimigo = inimigo_arqueiro_cena if randf() < chance_arqueiro else inimigo_guerreiro_cena
			
			spawns_agendados.append({
				"tempo": tempo_spawn,
				"cena": cena_inimigo,
				"rota": rota,
				"spawnado": false
			})

	# Garante um spawn no início e outro no final em rotas aleatórias
	if rotas.size() > 0:
		var rota_inicio = rotas[randi_range(0, rotas.size() - 1)]
		var rota_final = rotas[randi_range(0, rotas.size() - 1)]
		var cena_inicio = inimigo_arqueiro_cena if randf() < chance_arqueiro else inimigo_guerreiro_cena
		var cena_final = inimigo_arqueiro_cena if randf() < chance_arqueiro else inimigo_guerreiro_cena
		spawns_agendados.append({
			"tempo": 0.2,
			"cena": cena_inicio,
			"rota": rota_inicio,
			"spawnado": false
		})
		spawns_agendados.append({
			"tempo": duracao_orda,
			"cena": cena_final,
			"rota": rota_final,
			"spawnado": false
		})
	
	# Ordena por tempo
	spawns_agendados.sort_custom(func(a, b): return a["tempo"] < b["tempo"])

func processar_orda(delta: float):
	# Só avança o tempo se ainda não chegou no limite
	if tempo_orda < duracao_orda:
		tempo_orda += delta
		if tempo_orda > duracao_orda:
			tempo_orda = duracao_orda
	
	# Processa spawns agendados
	for spawn_data in spawns_agendados:
		if not spawn_data["spawnado"] and tempo_orda >= spawn_data["tempo"]:
			spawnar_inimigo(spawn_data["rota"], spawn_data["cena"])
			spawn_data["spawnado"] = true
	
	# Verifica se a orda acabou (tempo completo + todos spawnados + sem inimigos vivos)
	if tempo_orda >= duracao_orda:
		var todos_spawnados = true
		for spawn_data in spawns_agendados:
			if not spawn_data["spawnado"]:
				todos_spawnados = false
				break
		
		if todos_spawnados and inimigos_vivos == 0:
			print("Orda ", orda_atual, " concluída!")
			aguardando_proxima_orda = true
			tempo_espera_orda = delay_entre_ordas

func spawnar_inimigo(rota, cena_do_inimigo):
	var novo_inimigo = cena_do_inimigo.instantiate()
	var inicio = rota.curve.get_point_position(0)
	
	novo_inimigo.global_position = rota.to_global(inicio)
	novo_inimigo.inimigo_morreu.connect(_on_inimigo_morreu)
	
	add_child(novo_inimigo)
	novo_inimigo.definir_rota(rota, base)
	
	inimigos_vivos += 1

func _on_inimigo_morreu(valor):
	inimigos_vivos -= 1
	receber_recompensa(valor)
	
	# Verifica se pode iniciar próxima orda
	if inimigos_vivos == 0 and tempo_orda >= duracao_orda:
		var todos_spawnados = true
		for spawn_data in spawns_agendados:
			if not spawn_data["spawnado"]:
				todos_spawnados = false
				break
		
		if todos_spawnados:
			print("Todos inimigos eliminados! Próxima orda em ", delay_entre_ordas, "s")
			aguardando_proxima_orda = true
			tempo_espera_orda = delay_entre_ordas

# --- ECONOMIA E UI ---
func verificar_saldo(custo) -> bool:
	if ouro_atual >= custo: return true
	print("Ouro insuficiente!")
	return false

func atualizar_interface_ouro():
	if label_ouro: label_ouro.text = "Ouro: " + str(ouro_atual)

func atualizar_interface_orda():
	if label_orda:
		if orda_atual > total_ordas:
			label_orda.text = "VITÓRIA!"
		else:
			label_orda.text = "Orda: " + str(orda_atual) + "/" + str(total_ordas)

func atualizar_interface_timer(tempo: float, eh_espera: bool):
	if label_timer:
		var minutos = int(tempo) / 60
		var segundos = int(tempo) % 60
		var texto_tempo = "%d:%02d" % [minutos, segundos]
		if eh_espera:
			label_timer.text = "Próxima: " + texto_tempo
		else:
			label_timer.text = "Tempo: " + texto_tempo

func receber_recompensa(valor):
	ouro_atual += valor
	atualizar_interface_ouro()

# --- SELEÇÃO DE TROPAS ---
func selecionar_guerreiro():
	if verificar_saldo(custo_guerreiro):
		configurar_construcao(tropa_guerreiro_cena, custo_guerreiro)

func selecionar_arqueiro():
	if verificar_saldo(custo_arqueiro):
		configurar_construcao(tropa_arqueiro_cena, custo_arqueiro)

func selecionar_monge():
	if verificar_saldo(custo_monge):
		configurar_construcao(tropa_monge_cena, custo_monge)

func configurar_construcao(cena, custo):
	print("Selecionado. Custo: ", custo)
	tropa_para_construir = cena
	custo_da_tropa_selecionada = custo
	criar_preview()

# --- CONEXÃO DOS BOTÕES (UI) ---
func _on_guerreiro_pressed() -> void: selecionar_guerreiro()
func _on_arqueiro_pressed() -> void: selecionar_arqueiro()
func _on_monge_pressed() -> void: selecionar_monge()

# --- CONSTRUÇÃO (PREVIEW E CLIQUE) ---
func criar_preview():
	if sprite_preview != null: sprite_preview.queue_free()
	sprite_preview = tropa_para_construir.instantiate()
	add_child(sprite_preview)
	sprite_preview.modulate = Color(1, 1, 1, 0.5) 
	sprite_preview.process_mode = Node.PROCESS_MODE_DISABLED

	# Ajusta orientação do preview conforme clique usado para comprar
	sprite_preview.scale.x = abs(sprite_preview.scale.x) if preview_facing_right else -abs(sprite_preview.scale.x)

	# Mantém nós visuais, desativando colisões e detecções para o preview
	for filho in sprite_preview.get_children():
		if filho is CollisionShape2D:
			filho.disabled = true
		elif filho is Area2D:
			# Desativa monitoramento para não interferir no preview
			filho.set_deferred("monitoring", false)
			filho.collision_layer = 0
			filho.collision_mask = 0
		elif filho is ProgressBar:
			filho.hide()
			
	sprite_preview.collision_layer = 0
	sprite_preview.collision_mask = 0

func atualizar_preview():
	if sprite_preview != null:
		var mouse_pos = get_global_mouse_position()
		var coord_grid = tile_map.local_to_map(mouse_pos)
		sprite_preview.position = tile_map.map_to_local(coord_grid)

		# Aplica orientação do alcance para tiles marcados como verticais
		var dados_tile = tile_map.get_cell_tile_data(coord_grid)
		if dados_tile and sprite_preview.get_script() != null:
			var eh_vertical: bool = bool(dados_tile.get_custom_data("alcance_vertical"))
			# Apenas para o preview do arqueiro
			var script_path := str(sprite_preview.get_script().resource_path)
			if script_path.find("tropa_arqueiro.gd") != -1:
				_aplicar_orientacao_alcance(sprite_preview, eh_vertical)

		# Garante espelhamento persistente do preview
		sprite_preview.scale.x = abs(sprite_preview.scale.x) if preview_facing_right else -abs(sprite_preview.scale.x)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and tropa_para_construir != null:
			# Esquerdo: constrói usando a orientação do preview
			tentar_construir(preview_facing_right)
			segurando_esq = true
			tempo_hold = INTERVALO_HOLD
		elif event.button_index == MOUSE_BUTTON_RIGHT and tropa_para_construir != null:
			# Direito: cancelar construção
			cancelar_construcao()
	elif event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			segurando_esq = false
	elif event is InputEventKey and event.pressed and not event.echo:
		# ESC (ui_cancel) para cancelar
		if event.keycode == KEY_ESCAPE and tropa_para_construir != null:
			cancelar_construcao()
		# Setas esquerda/direita controlam orientação do preview
		elif event.keycode == KEY_LEFT and tropa_para_construir != null:
			preview_facing_right = false
			if sprite_preview != null:
				sprite_preview.scale.x = -abs(sprite_preview.scale.x)
		elif event.keycode == KEY_RIGHT and tropa_para_construir != null:
			preview_facing_right = true
			if sprite_preview != null:
				sprite_preview.scale.x = abs(sprite_preview.scale.x)

# (Removidos handlers gui_input; orientação agora é pelas setas ← →)

func tentar_construir(facing_right: bool = true):
	if ouro_atual < custo_da_tropa_selecionada:
		cancelar_construcao()
		return

	var mouse_pos = get_global_mouse_position()
	var coord_grid = tile_map.local_to_map(mouse_pos)
	
	# Calcula a posição exata onde a tropa vai ficar (no centro do quadrado)
	var posicao_final = tile_map.map_to_local(coord_grid)

	# --- A MÁGICA DA COLISÃO COMEÇA AQUI ---
	
	# 1. Pegamos o estado físico do mundo atual
	var mundo_fisico = get_world_2d().direct_space_state
	
	# 2. Criamos uma "pergunta" para a física (Query)
	var parametros = PhysicsPointQueryParameters2D.new()
	parametros.position = posicao_final # Onde queremos checar?
	parametros.collide_with_bodies = true # Queremos detectar Corpos (StaticBody)? Sim.
	parametros.collide_with_areas = false # Queremos detectar Areas? Não (opcional).
	
	# IMPORTANTE: Isso assume que suas tropas estão na Collision Layer 1
	# Se estiverem em outra, mude aqui: parametros.collision_mask = 1 
	
	# 3. Fazemos a pergunta: "Quem está nesse ponto?"
	var resultado = mundo_fisico.intersect_point(parametros)
	

	var dados_tile = tile_map.get_cell_tile_data(coord_grid)
	
	if dados_tile and dados_tile.get_custom_data("pode_construir") and resultado.size() == 0:
		ouro_atual -= custo_da_tropa_selecionada
		atualizar_interface_ouro()
		
		var nova_tropa = tropa_para_construir.instantiate()
		nova_tropa.position = posicao_final
		# Define orientação inicial (direita/esquerda)
		nova_tropa.scale.x = abs(nova_tropa.scale.x) if facing_right else -abs(nova_tropa.scale.x)
		# Ajusta orientação do alcance conforme tile
		if dados_tile and nova_tropa.get_script() != null:
			var eh_vertical: bool = bool(dados_tile.get_custom_data("alcance_vertical"))
			var script_path := str(nova_tropa.get_script().resource_path)
			if script_path.find("tropa_arqueiro.gd") != -1:
				_aplicar_orientacao_alcance(nova_tropa, eh_vertical)
		add_child(nova_tropa)
		# Mantém seleção ativa para construir outra unidade
	else:
		print("Terreno inválido!")

# --- AUXILIAR: aplica rotação do AreaAlcance ---
func _aplicar_orientacao_alcance(node_aliado: Node2D, eh_vertical: bool):
	if node_aliado.has_node("AreaAlcance"):
		var area: Node2D = node_aliado.get_node_or_null("AreaAlcance") as Node2D
		if area:
			area.rotation_degrees = 90 if eh_vertical else 0

func cancelar_construcao():
	tropa_para_construir = null
	custo_da_tropa_selecionada = 0
	if sprite_preview != null:
		sprite_preview.queue_free()
		sprite_preview = null
	segurando_esq = false
