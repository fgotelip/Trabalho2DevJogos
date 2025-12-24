extends Node2D

# Referência para o TileMap onde estão as estradas (ajuste o nome se for diferente)
@onready var tile_map = $Camada_Chao 

# Variável para guardar onde o mouse está no grid (ex: 2, 5)
var celula_mouse = Vector2i.ZERO

func _process(_delta):
	# 1. Pega a posição do mouse no mundo
	var mouse_pos = get_global_mouse_position()
	
	# 2. Converte Pixels -> Coordenada de Grid (O segredo do jogo!)
	# A função local_to_map faz a mágica de transformar (150px, 300px) em (2, 4)
	var nova_celula = tile_map.local_to_map(mouse_pos)
	
	# Só processamos se o mouse mudou de célula (otimização)
	if nova_celula != celula_mouse:
		celula_mouse = nova_celula
		verificar_terreno(celula_mouse)

func verificar_terreno(coord: Vector2i):
	# 3. Pegamos os DADOS do tile nessa coordenada
	var dados_tile = tile_map.get_cell_tile_data(coord)
	
	if dados_tile:
		# Pergunta: "Esse tile tem a etiqueta 'pode_construir' verdadeira?"
		# 'pode_construir' é o nome exato que demos no passo anterior
		var eh_construtivel = dados_tile.get_custom_data("pode_construir")
		#
		if eh_construtivel:
			print("Mouse em cima de ESTRADA VÁLIDA: ", coord)
		else:
			print("Terreno inválido (Grama/Muro)")
	else:
		print("Fora do mapa")
