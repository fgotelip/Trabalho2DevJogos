extends Control

@onready var container_principal = $ContainerPrincipal
@onready var container_dificuldade = $ContainerDificuldade


func _on_botao_iniciar_pressed():
	container_principal.visible = false
	container_dificuldade.visible = true

func _on_botao_sair_pressed():
	get_tree().quit()

func _on_btn_facil_pressed():
	iniciar_jogo("facil")

func _on_btn_normal_pressed():
	iniciar_jogo("normal")

func _on_btn_dificil_pressed():
	iniciar_jogo("dificil")

func _on_btn_voltar_pressed():
	container_dificuldade.visible = false
	container_principal.visible = true

func iniciar_jogo(dificuldade: String):
	Global.configurar_dificuldade(dificuldade)
	
	get_tree().change_scene_to_file("res://Scene/main_scene.tscn")
