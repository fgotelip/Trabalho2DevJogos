extends Node2D

@onready var tile_map = $Camada_Chao 
@onready var ui = $InterfaceUsuario 
@onready var label_ouro = $InterfaceUsuario/LabelOuro 
@onready var label_orda = $InterfaceUsuario/LabelOrda
@onready var label_timer = $InterfaceUsuario/LabelTimer
@onready var rotas = $Rotas.get_children() 
@onready var base = $Base

var custo_guerreiro: int = 100
var custo_arqueiro: int = 150
var custo_monge: int = 350
var ouro_atual: int = 1000 

var tropa_guerreiro_cena = preload("res://Scene/tropa_barreira.tscn") 
var tropa_arqueiro_cena = preload("res://Scene/tropa_arqueiro.tscn")
var tropa_monge_cena = preload("res://Scene/tropa_monge.tscn")

var inimigo_guerreiro_cena = preload("res://Scene/inimigo_guerreiro.tscn") 
var inimigo_arqueiro_cena = preload("res://Scene/inimigo_arqueiro.tscn")

var tropa_para_construir = null 
var custo_da_tropa_selecionada: int = 0
var sprite_preview = null 
var preview_facing_right: bool = true
var segurando_esq: bool = false
var tempo_hold: float = 0.0
const INTERVALO_HOLD: float = 0.2

var orda_atual: int = 0
var inimigos_vivos: int = 0
var spawns_agendados: Array = []
var tempo_orda: float = 0.0
var aguardando_proxima_orda: bool = false
var tempo_espera_orda: float = 0.0

@export var duracao_orda: float = 75.0 
@export var delay_entre_ordas: float = 15.0
@export var total_ordas: int = 4

@export var faixas_inimigos_por_orda: Array[Vector2i] = [
	Vector2i(1, 3), 
	Vector2i(3, 5), 
	Vector2i(5, 7), 
	Vector2i(9, 11)
]
@export var chance_arqueiro_por_orda: Array[float] = [0.5, 0.6, 0.6, 0.7]

var jogo_acabou: bool = false
var btn_mute: Button = null

func _ready():
	atualizar_interface_ouro()
	atualizar_interface_orda()
	
	if base.has_signal("base_destruida"):
		if not base.base_destruida.is_connected(_on_game_over):
			base.base_destruida.connect(_on_game_over)
	
	criar_botao_mute()
	
	iniciar_proxima_orda()

func _process(_delta):
	if jogo_acabou:
		return

	if Input.is_action_just_pressed("selecionar_tropa_1"):
		selecionar_guerreiro()
	elif Input.is_action_just_pressed("selecionar_tropa_2"):
		selecionar_arqueiro()
	elif Input.is_action_just_pressed("selecionar_tropa_3"):
		selecionar_monge()

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
		
		if segurando_esq:
			tempo_hold -= _delta
			if tempo_hold <= 0.0:
				tentar_construir(preview_facing_right)
				tempo_hold = INTERVALO_HOLD

	if Input.is_action_just_pressed("ui_cancel") and tropa_para_construir != null:
		cancelar_construcao()

func criar_botao_mute():
	btn_mute = Button.new()
	
	if Global.esta_mutado:
		btn_mute.text = "SOM: OFF"
		btn_mute.modulate = Color(1, 0.5, 0.5)
	else:
		btn_mute.text = "SOM: ON"
		btn_mute.modulate = Color(0.5, 1, 0.5)
		
	btn_mute.size = Vector2(100, 40)
	var tela_size = get_viewport_rect().size
	btn_mute.position = Vector2(tela_size.x - 120, 20)
	
	btn_mute.pressed.connect(_on_mute_pressed)
	ui.add_child(btn_mute)

func _on_mute_pressed():
	var esta_mudo = Global.alternar_som()
	
	if esta_mudo:
		btn_mute.text = "SOM: OFF"
		btn_mute.modulate = Color(1, 0.5, 0.5)
	else:
		btn_mute.text = "SOM: ON"
		btn_mute.modulate = Color(0.5, 1, 0.5)

func _on_game_over():
	if jogo_acabou:
		return 
		
	jogo_acabou = true
	print("!!! A BASE CAIU !!!")
	get_tree().paused = true 
	
	exibir_tela_final("GAME OVER", Color.RED, false)

func verificar_vitoria_total():
	if orda_atual >= total_ordas and inimigos_vivos == 0:
		jogo_acabou = true
		print("!!! VITÓRIA !!!")
		
		exibir_tela_final("VITÓRIA!", Color.GREEN, true)

func exibir_tela_final(texto_titulo: String, cor_titulo: Color, mostrar_creditos: bool = false):
	if btn_mute:
		btn_mute.hide()
	
	var tela_size = get_viewport_rect().size
	var centro_tela = tela_size / 2
	
	var label = Label.new()
	label.text = texto_titulo
	label.modulate = cor_titulo
	label.add_theme_font_size_override("font_size", 80)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(600, 100)
	label.position = centro_tela - (label.size / 2) - Vector2(0, 100) 
	ui.add_child(label)
	
	var btn_reiniciar = Button.new()
	btn_reiniciar.text = "Jogar Novamente"
	btn_reiniciar.size = Vector2(250, 60)
	btn_reiniciar.position = centro_tela - (btn_reiniciar.size / 2)
	
	btn_reiniciar.pressed.connect(_on_reiniciar_pressed)
	btn_reiniciar.process_mode = Node.PROCESS_MODE_ALWAYS 
	ui.add_child(btn_reiniciar)

	if mostrar_creditos:
		var btn_creditos = Button.new()
		btn_creditos.text = "Ver Créditos"
		btn_creditos.size = Vector2(250, 60)
		btn_creditos.position = btn_reiniciar.position + Vector2(0, 70) 
		
		btn_creditos.pressed.connect(_ir_para_creditos)
		btn_creditos.process_mode = Node.PROCESS_MODE_ALWAYS
		ui.add_child(btn_creditos)

func _on_reiniciar_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _ir_para_creditos():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scene/creditos.tscn")

func iniciar_proxima_orda():
	if orda_atual >= total_ordas:
		return
	
	orda_atual += 1
	aguardando_proxima_orda = false
	tempo_orda = 0.0
	spawns_agendados.clear()
	
	atualizar_interface_orda()

	var idx_orda: int = max(orda_atual - 1, 0)
	var faixa_default: Vector2i = Vector2i(3, 5)
	var chance_default: float = 0.5
	
	var faixa_orda: Vector2i = faixas_inimigos_por_orda[idx_orda] if idx_orda < faixas_inimigos_por_orda.size() else faixa_default
	var chance_arqueiro: float = chance_arqueiro_por_orda[idx_orda] if idx_orda < chance_arqueiro_por_orda.size() else chance_default

	for rota in rotas:
		var num_inimigos_nesta_rota = randi_range(faixa_orda.x, faixa_orda.y)
		var tempos_spawn_rota: Array = []
		
		for _i in range(num_inimigos_nesta_rota):
			tempos_spawn_rota.append(randf_range(1.0, duracao_orda - 1.0))
		
		tempos_spawn_rota.sort()
		
		for tempo_spawn in tempos_spawn_rota:
			var cena_inimigo = inimigo_arqueiro_cena if randf() < chance_arqueiro else inimigo_guerreiro_cena
			spawns_agendados.append({
				"tempo": tempo_spawn, 
				"cena": cena_inimigo, 
				"rota": rota, 
				"spawnado": false
			})

	if rotas.size() > 0:
		var rota_inicio = rotas.pick_random()
		var rota_final = rotas.pick_random()
		var cena_inicio = inimigo_arqueiro_cena if randf() < chance_arqueiro else inimigo_guerreiro_cena
		var cena_final = inimigo_arqueiro_cena if randf() < chance_arqueiro else inimigo_guerreiro_cena
		
		spawns_agendados.append({"tempo": 0.2, "cena": cena_inicio, "rota": rota_inicio, "spawnado": false})
		spawns_agendados.append({"tempo": duracao_orda, "cena": cena_final, "rota": rota_final, "spawnado": false})
	
	spawns_agendados.sort_custom(func(a, b): return a["tempo"] < b["tempo"])

func processar_orda(delta: float):
	if tempo_orda < duracao_orda:
		tempo_orda += delta
		if tempo_orda > duracao_orda:
			tempo_orda = duracao_orda

	for spawn_data in spawns_agendados:
		if not spawn_data["spawnado"] and tempo_orda >= spawn_data["tempo"]:
			spawnar_inimigo(spawn_data["rota"], spawn_data["cena"])
			spawn_data["spawnado"] = true
	
	if tempo_orda >= duracao_orda:
		var todos_spawnados = true
		for spawn_data in spawns_agendados:
			if not spawn_data["spawnado"]:
				todos_spawnados = false
				break
		
		if todos_spawnados and inimigos_vivos == 0:
			if orda_atual < total_ordas:
				print("Onda ", orda_atual, " concluída!")
				aguardando_proxima_orda = true
				tempo_espera_orda = delay_entre_ordas
			else:
				verificar_vitoria_total()

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
	if inimigos_vivos == 0 and tempo_orda >= duracao_orda:
		var todos_spawnados = true
		for spawn_data in spawns_agendados:
			if not spawn_data["spawnado"]:
				todos_spawnados = false
				break
		if todos_spawnados:
			if orda_atual < total_ordas:
				aguardando_proxima_orda = true
				tempo_espera_orda = delay_entre_ordas
			else:
				verificar_vitoria_total()

func verificar_saldo(custo) -> bool:
	if ouro_atual >= custo:
		return true
		
	print("Ouro insuficiente!")
	return false

func atualizar_interface_ouro():
	if label_ouro:
		label_ouro.text = "Ouro: " + str(ouro_atual)

func atualizar_interface_orda():
	if label_orda:
		label_orda.text = "Onda: " + str(orda_atual) + "/" + str(total_ordas)

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
	tropa_para_construir = cena
	custo_da_tropa_selecionada = custo
	criar_preview()

func _on_guerreiro_pressed() -> void:
	selecionar_guerreiro()
	
func _on_arqueiro_pressed() -> void:
	selecionar_arqueiro()
	
func _on_monge_pressed() -> void:
	selecionar_monge()

func criar_preview():
	if sprite_preview != null:
		sprite_preview.queue_free()
		
	sprite_preview = tropa_para_construir.instantiate()
	add_child(sprite_preview)
	sprite_preview.modulate = Color(1, 1, 1, 0.5) 
	sprite_preview.process_mode = Node.PROCESS_MODE_DISABLED
	
	if preview_facing_right:
		sprite_preview.scale.x = abs(sprite_preview.scale.x)
	else:
		sprite_preview.scale.x = -abs(sprite_preview.scale.x)
		
	for filho in sprite_preview.get_children():
		if filho is CollisionShape2D:
			filho.disabled = true
		elif filho is Area2D:
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

		var dados_tile = tile_map.get_cell_tile_data(coord_grid)
		if dados_tile and sprite_preview.get_script() != null:
			var eh_vertical: bool = bool(dados_tile.get_custom_data("alcance_vertical"))
			var script_path := str(sprite_preview.get_script().resource_path)
			
			if script_path.find("tropa_arqueiro.gd") != -1:
				_aplicar_orientacao_alcance(sprite_preview, eh_vertical)
		
		if preview_facing_right:
			sprite_preview.scale.x = abs(sprite_preview.scale.x)
		else:
			sprite_preview.scale.x = -abs(sprite_preview.scale.x)

func _unhandled_input(event):
	if jogo_acabou:
		return

	if event.is_action_pressed("cheat_vitoria"):
		print("CHEAT ATIVADO: Vitória Instantânea!")
		jogo_acabou = true
		exibir_tela_final("VITÓRIA (DEBUG)!", Color.GREEN, true)

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and tropa_para_construir != null:
			tentar_construir(preview_facing_right)
			segurando_esq = true
			tempo_hold = INTERVALO_HOLD
			
		elif event.button_index == MOUSE_BUTTON_RIGHT and tropa_para_construir != null:
			cancelar_construcao()
			
	elif event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			segurando_esq = false
			
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and tropa_para_construir != null:
			cancelar_construcao()
			
		elif event.keycode == KEY_LEFT and tropa_para_construir != null:
			preview_facing_right = false
			if sprite_preview != null:
				sprite_preview.scale.x = -abs(sprite_preview.scale.x)
				
		elif event.keycode == KEY_RIGHT and tropa_para_construir != null:
			preview_facing_right = true
			if sprite_preview != null:
				sprite_preview.scale.x = abs(sprite_preview.scale.x)

	if event is InputEventKey and event.pressed and event.keycode == KEY_ASTERISK:
		print("CHEAT ATIVADO: Vitória Instantânea!")
		jogo_acabou = true
		exibir_tela_final("VITÓRIA (DEBUG)!", Color.GREEN, true)

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and tropa_para_construir != null:
			tentar_construir(preview_facing_right)
			segurando_esq = true
			tempo_hold = INTERVALO_HOLD
			
		elif event.button_index == MOUSE_BUTTON_RIGHT and tropa_para_construir != null:
			cancelar_construcao()
			
	elif event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			segurando_esq = false
			
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and tropa_para_construir != null:
			cancelar_construcao()
			
		elif event.keycode == KEY_LEFT and tropa_para_construir != null:
			preview_facing_right = false
			if sprite_preview != null:
				sprite_preview.scale.x = -abs(sprite_preview.scale.x)
				
		elif event.keycode == KEY_RIGHT and tropa_para_construir != null:
			preview_facing_right = true
			if sprite_preview != null:
				sprite_preview.scale.x = abs(sprite_preview.scale.x)

func tentar_construir(facing_right: bool = true):
	if ouro_atual < custo_da_tropa_selecionada:
		cancelar_construcao()
		return

	var mouse_pos = get_global_mouse_position()
	var coord_grid = tile_map.local_to_map(mouse_pos)
	var posicao_final = tile_map.map_to_local(coord_grid)
	
	var mundo_fisico = get_world_2d().direct_space_state
	var parametros = PhysicsPointQueryParameters2D.new()
	parametros.position = posicao_final
	parametros.collide_with_bodies = true
	parametros.collide_with_areas = false
	
	var resultado = mundo_fisico.intersect_point(parametros)
	var dados_tile = tile_map.get_cell_tile_data(coord_grid)
	
	if dados_tile and dados_tile.get_custom_data("pode_construir") and resultado.size() == 0:
		ouro_atual -= custo_da_tropa_selecionada
		atualizar_interface_ouro()
		
		var nova_tropa = tropa_para_construir.instantiate()
		nova_tropa.position = posicao_final
		
		if facing_right:
			nova_tropa.scale.x = abs(nova_tropa.scale.x)
		else:
			nova_tropa.scale.x = -abs(nova_tropa.scale.x)
		
		if dados_tile and nova_tropa.get_script() != null:
			var eh_vertical: bool = bool(dados_tile.get_custom_data("alcance_vertical"))
			var script_path := str(nova_tropa.get_script().resource_path)
			
			if script_path.find("tropa_arqueiro.gd") != -1:
				_aplicar_orientacao_alcance(nova_tropa, eh_vertical)
		
		add_child(nova_tropa)
	else:
		print("Construção bloqueada!")

func _aplicar_orientacao_alcance(node_aliado: Node2D, eh_vertical: bool):
	if node_aliado.has_node("AreaAlcance"):
		var area: Node2D = node_aliado.get_node_or_null("AreaAlcance")
		
		if area:
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
		
	segurando_esq = false
