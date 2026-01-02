extends Node

# Multiplicadores de Dificuldade (Padrão = Normal = 1.0)
var multiplicador_vida: float = 1.0
var multiplicador_dano: float = 1.0

func configurar_dificuldade(nivel: String):
	match nivel:
		"facil":
			multiplicador_vida = 0.6  # Inimigos com 60% da vida
			multiplicador_dano = 0.5  # Inimigos batem fraco
		"normal":
			multiplicador_vida = 1.0
			multiplicador_dano = 1.0
		"dificil":
			multiplicador_vida = 1.5  # 50% mais vida
			multiplicador_dano = 2.0  # Dobro de dano
