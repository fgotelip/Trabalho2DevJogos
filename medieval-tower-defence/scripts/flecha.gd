extends Area2D

var velocidade: float = 400.0
var dano: int = 10
var alvo_e_inimigo: bool = true 

func _ready():
	body_entered.connect(_on_body_entered)
	
	# --- CORREÇÃO DE SEGURANÇA ---
	# Se a flecha deve acertar INIMIGOS
	if alvo_e_inimigo:
		collision_mask = 0  # Reseta tudo
		set_collision_mask_value(2, true) # Só enxerga Layer 2 (Inimigos)
		
	# Se a flecha deve acertar ALIADOS (Inimigo atirando)
	else:
		collision_mask = 0
		set_collision_mask_value(3, true) # Só enxerga Layer 3 (Aliados)
		set_collision_mask_value(4, true) # Só enxerga Layer 4 (Base)

	# Destrói depois de 3 segundos
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta):
	position += transform.x * velocidade * delta

func _on_body_entered(body):
	# O filtro de colisão acima já resolve 99% dos problemas, 
	# mas mantemos isso por segurança:
	if body.has_method("receber_dano"):
		body.receber_dano(dano)
		queue_free()
