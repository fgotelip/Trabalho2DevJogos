extends Node2D

# --- REFERÊNCIAS ---
@onready var tile_map = $Camada_Chao 
@onready var ui = $InterfaceUsuario 
@onready var label_ouro = $InterfaceUsuario/LabelOuro 
#@onready var rotas = $Rotas.get_children() 
@onready var rotas = [$Rotas/Rota11]
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

func _ready():
	atualizar_interface_ouro()

func _process(_delta):
	# Teclas de Atalho de Compra
	if Input.is_action_just_pressed("selecionar_tropa_1"): selecionar_guerreiro()
	elif Input.is_action_just_pressed("selecionar_tropa_2"): selecionar_arqueiro()
	elif Input.is_action_just_pressed("selecionar_tropa_3"): selecionar_monge()

	# ESPAÇO: SPAWN MISTO
	if Input.is_action_just_pressed("ui_accept"):
		spawnar_inimigos(0)
	if Input.is_action_just_pressed("ui_focus_next"):
		spawnar_inimigos(1)

	if tropa_para_construir != null:
		atualizar_preview()

	# ESC para cancelar construção
	if Input.is_action_just_pressed("ui_cancel") and tropa_para_construir != null:
		cancelar_construcao()

# --- SPAWN DE INIMIGOS (ATUALIZADO) ---
func spawnar_inimigos(teste):
	print("Iniciando onda mista!")
	for rota in rotas:
		# 50% de chance para cada um. 
		# Se quiser mais guerreiros, faça: [inimigo_guerreiro_cena, inimigo_guerreiro_cena, inimigo_arqueiro_cena]
		var lista_inimigos = [inimigo_guerreiro_cena, inimigo_arqueiro_cena]
		var tipo_sorteado = lista_inimigos[teste]
		#var tipo_sorteado = inimigo_arqueiro_cena
		spawnar_inimigo(rota, tipo_sorteado)

func spawnar_inimigo(rota, cena_do_inimigo):
	var novo_inimigo = cena_do_inimigo.instantiate()
	var inicio = rota.curve.get_point_position(0)
	
	novo_inimigo.global_position = rota.to_global(inicio)
	novo_inimigo.inimigo_morreu.connect(receber_recompensa)
	
	add_child(novo_inimigo)
	novo_inimigo.definir_rota(rota, base)

# --- ECONOMIA E UI ---
func verificar_saldo(custo) -> bool:
	if ouro_atual >= custo: return true
	print("Ouro insuficiente!")
	return false

func atualizar_interface_ouro():
	if label_ouro: label_ouro.text = "Ouro: " + str(ouro_atual)

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
		elif event.button_index == MOUSE_BUTTON_RIGHT and tropa_para_construir != null:
			# Direito: cancelar construção
			cancelar_construcao()
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
		
		cancelar_construcao() 
	else:
		print("Terreno inválido!")

# --- AUXILIAR: aplica rotação do AreaAlcance ---
func _aplicar_orientacao_alcance(node_aliado: Node2D, eh_vertical: bool):
	if node_aliado.has_node("AreaAlcance"):
		var area := node_aliado.get_node("AreaAlcance")
		if eh_vertical:
			area.rotation_degrees = 90
		else:
			area.rotation_degrees = 0

func cancelar_construcao():
	tropa_para_construir = null
	custo_da_tropa_selecionada = 0
	if sprite_preview != null:
		sprite_preview.queue_free()
		sprite_preview = null
