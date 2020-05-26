extends Node2D

func set_text(_txt, _isCrit):
	$Timer.start()
	$Label.text = str(_txt)
	if _isCrit == 1:
		$Label.set_modulate(Color.yellow)
	elif _isCrit == 2:
		$Label.set_modulate(Color.red)
	else:
		$Label.set_modulate(Color.green)
func _on_Timer_timeout():
	$Label.text = str("")

func update():
	$".".position.y += $".".position.y  + 5


func clear():
	$Label.text = str("")
