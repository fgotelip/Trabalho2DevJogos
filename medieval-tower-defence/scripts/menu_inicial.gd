extends Control

@onready var container_principal = $ContainerPrincipal
@onready var container_dificuldade = $ContainerDificuldade

# --- BOTÕES PRINCIPAIS ---

func _on_botao_iniciar_pressed():
	# Troca os painéis
	container_principal.visible = false
	container_dificuldade.visible = true

func _on_botao_sair_pressed():
	get_tree().quit() # Fecha o jogo

# --- BOTÕES DE DIFICULDADE ---

func _on_btn_facil_pressed():
	iniciar_jogo("facil")

func _on_btn_normal_pressed():
	iniciar_jogo("normal")

func _on_btn_dificil_pressed():
	iniciar_jogo("dificil")

func _on_btn_voltar_pressed():
	# Volta para o menu principal
	container_dificuldade.visible = false
	container_principal.visible = true

# --- LÓGICA DE CARREGAMENTO ---
func iniciar_jogo(dificuldade: String):
	# 1. Configura o Global
	Global.configurar_dificuldade(dificuldade)
	
	# 2. Muda para a cena do jogo (Main Scene)
	# CONFIRA SE O CAMINHO ESTÁ CERTO!
	get_tree().change_scene_to_file("res://Scene/main_scene.tscn")
