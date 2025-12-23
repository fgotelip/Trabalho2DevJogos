extends Entidade

signal base_destruida # criamos um sinal que será emitido quando a base for destruida para gerenciar o que vai acontecer

func morrer():
	print("Game over")
	
	base_destruida.emit()
	
	queue_free()
	
func _process(delta): # executada o tempo todo -> delta serve para igualar computadores diferentes
	if Input.is_action_just_pressed("ui_accept"):
		receber_dano(20)
		
	
	
