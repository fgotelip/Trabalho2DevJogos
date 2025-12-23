extends StaticBody2D

# --- ESTATÍSTICAS DA TROPA ---
# Usamos @export para poder ajustar esses números direto no Inspetor depois
@export_group("Atributos")
@export var vida_maxima: int = 100
@export var dano: int = 10
@export var alcance: float = 150.0 # Em pixels
@export var preco: int = 50

# Variável interna para controlar a vida atual
var vida_atual: int

func _ready():
	# Quando o jogo começa (ou a tropa nasce), a vida enche
	vida_atual = vida_maxima

# Função para receber dano (usaremos isso quando o inimigo atacar)
func receber_dano(quantidade: int):
	vida_atual -= quantidade
	print("Barreira levou dano! Vida restante: ", vida_atual)
	
	if vida_atual <= 0:
		morrer()

func morrer():
	print("A barreira foi destruída!")
	queue_free() # Remove este objeto do jogo
