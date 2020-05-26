extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Novo_Jogo_button_down():
	get_tree().change_scene("res://Cenas/Game.tscn")


func _on_Tutorial_button_down():
	get_tree().change_scene("res://Cenas/Tutorial.tscn")


func _on_Sair_button_down():
	get_tree().quit()


func _on_Manual_button_down():
	get_tree().change_scene("res://Cenas/Manual.tscn")
