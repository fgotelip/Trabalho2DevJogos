extends Area2D

@export var velocidade: float = 400.0
@export var dano: int = 10
var alvo_e_inimigo: bool = true 

func _ready():
	body_entered.connect(_on_body_entered)
	
	if alvo_e_inimigo:
		collision_mask = 0 
		set_collision_mask_value(2, true) 
		
	else:
		collision_mask = 0
		set_collision_mask_value(3, true) 
		set_collision_mask_value(4, true) 

	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta):
	position += transform.x * velocidade * delta

func _on_body_entered(body):
	if body.has_method("receber_dano"):
		body.receber_dano(dano)
		queue_free()
