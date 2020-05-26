extends Node2D

var manualatual = 1

func _on_Proximo_button_down():
	match(manualatual):
		1:
			manualatual = manualatual + 1
			$CanvasLayer/Manual1.visible = false
			$CanvasLayer/Manual2.visible = true
		2:
			manualatual = manualatual + 1
			$CanvasLayer/Manual2.visible = false
			$CanvasLayer/Manual3.visible = true
		3:
			manualatual = manualatual + 1
			$CanvasLayer/Manual3.visible = false
			$CanvasLayer/Manual4.visible = true
		4:
			manualatual = manualatual + 1
			$CanvasLayer/Manual4.visible = false
			$CanvasLayer/Manual5.visible = true
		5:
			manualatual = manualatual + 1
			$CanvasLayer/Manual5.visible = false
			$CanvasLayer/Manual6.visible = true
		6:
			manualatual = manualatual + 1
			$CanvasLayer/Manual6.visible = false
			$CanvasLayer/Manual7.visible = true
		7:
			get_tree().change_scene("res://Cenas/Menu.tscn")


func _on_Anterior_button_down():
	match(manualatual):
		1:
			get_tree().change_scene("res://Cenas/Menu.tscn")
		2:
			manualatual = manualatual - 1
			$CanvasLayer/Manual2.visible = false
			$CanvasLayer/Manual1.visible = true
		3:
			manualatual = manualatual - 1
			$CanvasLayer/Manual3.visible = false
			$CanvasLayer/Manual2.visible = true
		4:
			manualatual = manualatual - 1
			$CanvasLayer/Manual4.visible = false
			$CanvasLayer/Manual3.visible = true
		5:
			manualatual = manualatual - 1
			$CanvasLayer/Manual5.visible = false
			$CanvasLayer/Manual4.visible = true
		6:
			manualatual = manualatual - 1
			$CanvasLayer/Manual6.visible = false
			$CanvasLayer/Manual5.visible = true
		7:
			manualatual = manualatual - 1
			$CanvasLayer/Manual7.visible = false
			$CanvasLayer/Manual6.visible = true
