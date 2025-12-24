extends Camera2D

# Configurações expostas no Inspector
@export var velocidade_movimento: int = 600
@export var margem_borda: int = 50 
@export var usar_mouse: bool = true # Checkbox para ligar/desligar o mouse se quiser

func _process(delta):
	var movimento = Vector2.ZERO

	# --- PARTE 1: Movimento pelo Teclado (WASD) ---
	# get_vector retorna (1, 0) se apertar Direita, (-1, 0) Esquerda, etc.
	# A ordem dos parâmetros é: Negativo X, Positivo X, Negativo Y, Positivo Y
	var input_teclado = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_teclado != Vector2.ZERO:
		movimento = input_teclado
	
	# --- PARTE 2: Movimento pelo Mouse (Opcional) ---
	#elif usar_mouse:
		#var mouse_pos = get_viewport().get_mouse_position()
		#var tamanho_tela = get_viewport_rect().size
		#
		## Verifica Esquerda/Direita
		#if mouse_pos.x < margem_borda:
			#movimento.x = -1
		#elif mouse_pos.x > tamanho_tela.x - margem_borda:
			#movimento.x = 1
			#
		## Verifica Cima/Baixo
		#if mouse_pos.y < margem_borda:
			#movimento.y = -1
		#elif mouse_pos.y > tamanho_tela.y - margem_borda:
			#movimento.y = 1
			
	# --- PARTE 3: Aplicação ---
	# normalizamos o movimento do mouse para não ficar mais rápido que o teclado
	if movimento.length() > 0:
		movimento = movimento.normalized()
		
		# Atualiza a posição
		position += movimento * velocidade_movimento * delta
		
		# Garante que não saia dos limites (Clamp)
		# Substitua 3200 e 2000 pelos tamanhos exatos do seu mapa se mudou
		position.x = clamp(position.x, 0, 3200)
		position.y = clamp(position.y, 0, 2000)
