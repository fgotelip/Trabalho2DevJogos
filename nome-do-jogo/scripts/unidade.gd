class_name Unidade extends Entidade

export_group("Comportamento") #criar pasta de exports
@export var velocidade: float = 100.0
@export var dano: float = 10.0
@export var cadencia_ataque: float = 1.0
@export var grupos_alvo: Array[String] = []

var alvo_atual: Node2D = null # Node2D pois é algo mais geral -> ele anda em direcao ao alvo que não necessariamente será uma entidade.. Podemos mandar ele andar para um ponto vazio
var pode_atacar: bool = true

@onready var timer_ataque = $Timer # onready garante que o nó timer foi criado, após criado ele atribui ele a variável

func _ready():
	super._ready() # rodar ready da entidade

	timer_ataque.wait_time = cadencia_ataque
	timer_ataque.one_shot = true # não fica rodando infinito, só roda denovo quando mandar
