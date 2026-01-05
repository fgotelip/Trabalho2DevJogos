extends Node

var multiplicador_vida: float = 1.0
var multiplicador_dano: float = 1.0

var audio_player = AudioStreamPlayer.new()
var esta_mutado: bool = false

func _ready():
	add_child(audio_player)
	
	var musica = load("res://Audio/musica_fundo.wav") 
	
	if musica:
		audio_player.stream = musica
		audio_player.volume_db = -10.0 
		audio_player.play() 
	else:
		print("ERRO: Música não encontrada em res://Audio/musica_fundo.wav")

func configurar_dificuldade(nivel: String):
	match nivel:
		"facil":
			multiplicador_vida = 0.6
			multiplicador_dano = 0.5
		"normal":
			multiplicador_vida = 1.0
			multiplicador_dano = 1.0
		"dificil":
			multiplicador_vida = 1.5
			multiplicador_dano = 2.0

func alternar_som() -> bool:
	esta_mutado = !esta_mutado
	audio_player.stream_paused = esta_mutado
	return esta_mutado
