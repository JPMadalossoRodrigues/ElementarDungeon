extends Node2D

const LabelScene = preload("res://Cenas/Label.tscn")
const AlmaScene = preload("res://Cenas/Almas.tscn")

const TILE_SIZE = 32

enum Tile { Parede, Chao, Porta, Pedra, Escada}
enum Elementos { Terra, Agua, Ar, Fogo}

onready var player = $Player
onready var tile_map = $TileMap

class Alma:
	var sprite_node
	var Elemento
	var tile
	
	func _init(_game, _elemento,_tile):
		Elemento = _elemento
		tile = _tile
		sprite_node = AlmaScene.instance()
		sprite_node.frame = _elemento 
		sprite_node.position = tile * TILE_SIZE
		sprite_node.position.x = sprite_node.position.x + randi()%16 - 8
		sprite_node.position.y = sprite_node.position.y + randi()%16 - 8
		_game.add_child(sprite_node)
	func remove():
		sprite_node.queue_free()


var player_tile = Vector2(4,6)
var player_hp_max = 100
var player_hp = 50
var player_dano = 10
var player_esquiva = 20

var inimigo_tile = Vector2(16,3)
var inimigo_hp_max = 20
var inimigo_hp = inimigo_hp_max
var inimigo_esquiva = 15
var inimigo_morto = false

var inimigo1_tile = Vector2(25,6)
var inimigo1_hp_max = 20
var inimigo1_hp = inimigo1_hp_max
var inimigo1_esquiva = 15
var inimigo1_morto = false

var inimigo2_tile = Vector2(25,8)
var inimigo2_hp_max = 20
var inimigo2_hp = inimigo2_hp_max
var inimigo2_esquiva = 15
var inimigo2_morto = false

var inimigo3_tile = Vector2(25,11)
var inimigo3_hp_max = 20
var inimigo3_hp = inimigo3_hp_max
var inimigo3_esquiva = 15
var inimigo3_morto = false

var inimigo4_tile = Vector2(25,13)
var inimigo4_hp_max = 20
var inimigo4_hp = inimigo4_hp_max
var inimigo4_esquiva = 15
var inimigo4_morto = false

var almasChao = []
var almasColetadas = []
var almaAtiva
var turnos = 0



func _ready():
	OS.set_window_size(Vector2(1280,720))
	randomize()
	$UI/HP.rect_size.x = 40 * player_hp/player_hp_max
	player.position = player_tile *  TILE_SIZE
	$Inimigos.position = inimigo_tile * TILE_SIZE
	$Inimigos1.position = inimigo1_tile * TILE_SIZE
	$Inimigos2.position = inimigo2_tile * TILE_SIZE
	$Inimigos3.position = inimigo3_tile * TILE_SIZE
	$Inimigos4.position = inimigo4_tile * TILE_SIZE
	atualiza_almas()

func _input(event):
	if !event.is_pressed():
		return
	if event.is_action("ui_end"):
		get_tree().quit()

	if event.is_action("ui_space"):
		if(!almasColetadas.empty()):
			match(almasColetadas[0].Elemento):
				Elementos.Terra:
					almaAtiva = Elementos.Terra
					turnos = 5
				Elementos.Agua:
					almaAtiva = Elementos.Agua
					turnos = 5
				Elementos.Ar:
					almaAtiva = Elementos.Ar
					turnos = 5
				Elementos.Fogo:
					almaAtiva = Elementos.Fogo
					turnos = 5
			$UI/UiPlayer.set_frame(almasColetadas[0].Elemento + 1)
			almasColetadas.erase(almasColetadas[0])
			atualiza_almas()
	if event.is_action("ui_left"):
		try_move(-1, 0)
	elif event.is_action("ui_right"):
		player.set_frame(0)
		try_move(1, 0)
	elif event.is_action("ui_up"):
		try_move(0, -1)
	elif event.is_action("ui_down"):
		try_move(0, 1)

func try_move(_x, _y):
		var x =  player_tile.x + _x
		var y =  player_tile.y + _y
		var tile_type = Tile.Pedra
		tile_type  = tile_map.get_cell(x,y)
		print(tile_type)
		print(Tile.Chao)
		match tile_type:
			Tile.Chao:
				var blocked = false
				if inimigo_tile.x == x && inimigo_tile.y == y && !inimigo_morto:
					var txt = LabelScene.instance()
					var PosX =inimigo_tile.x * TILE_SIZE 
					var PosY = inimigo_tile.y * TILE_SIZE  + 5
					txt.position = Vector2(PosX, PosY)
					txt.set_text(player_dano, 0)
					add_child(txt)
					inimigo_hp = min(inimigo_hp - player_dano, inimigo_hp_max)
					$Inimigos.get_node("HPBar").rect_size.x = TILE_SIZE * inimigo_hp/inimigo_hp_max
					if(inimigo_hp == 0):
						var alma = Alma.new(self,Elementos.Agua,inimigo_tile)
						almasChao.append(alma)
						$Inimigos.visible = false
						inimigo_morto = true
						$Inimigo.visible = false
						$Almas.visible = true
					blocked = true
				if inimigo1_tile.x == x && inimigo1_tile.y == y && !inimigo1_morto:
					var txt = LabelScene.instance()
					var PosX =inimigo1_tile.x * TILE_SIZE 
					var PosY = inimigo1_tile.y * TILE_SIZE  + 5
					txt.position = Vector2(PosX, PosY)
					txt.set_text(player_dano, 0)
					add_child(txt)
					inimigo1_hp = min(inimigo1_hp - player_dano, inimigo1_hp_max)
					$Inimigos1.get_node("HPBar").rect_size.x = TILE_SIZE * inimigo1_hp/inimigo1_hp_max
					if(inimigo1_hp == 0):
						var alma = Alma.new(self,Elementos.Terra,inimigo1_tile)
						almasChao.append(alma)
						$Inimigos1.visible = false
						inimigo1_morto = true
					blocked = true
				if inimigo2_tile.x == x && inimigo2_tile.y == y && !inimigo2_morto:
					var txt = LabelScene.instance()
					var PosX =inimigo2_tile.x * TILE_SIZE 
					var PosY = inimigo2_tile.y * TILE_SIZE  + 5
					txt.position = Vector2(PosX, PosY)
					txt.set_text(player_dano, 0)
					add_child(txt)
					inimigo2_hp = min(inimigo2_hp - player_dano, inimigo2_hp_max)
					$Inimigos2.get_node("HPBar").rect_size.x = TILE_SIZE * inimigo2_hp/inimigo2_hp_max
					if(inimigo2_hp == 0):
						var alma = Alma.new(self,Elementos.Agua,inimigo2_tile)
						almasChao.append(alma)
						$Inimigos2.visible = false
						inimigo2_morto = true
					blocked = true
				if inimigo3_tile.x == x && inimigo3_tile.y == y && !inimigo3_morto:
					var txt = LabelScene.instance()
					var PosX =inimigo3_tile.x * TILE_SIZE 
					var PosY = inimigo3_tile.y * TILE_SIZE  + 5
					txt.position = Vector2(PosX, PosY)
					txt.set_text(player_dano, 0)
					add_child(txt)
					inimigo3_hp = min(inimigo3_hp - player_dano, inimigo3_hp_max)
					$Inimigos3.get_node("HPBar").rect_size.x = TILE_SIZE * inimigo3_hp/inimigo3_hp_max
					if(inimigo3_hp == 0):
						var alma = Alma.new(self,Elementos.Fogo,inimigo3_tile)
						almasChao.append(alma)
						$Inimigos3.visible = false
						inimigo3_morto = true
					blocked = true
				if inimigo4_tile.x == x && inimigo4_tile.y == y && !inimigo4_morto:
					var txt = LabelScene.instance()
					var PosX =inimigo4_tile.x * TILE_SIZE 
					var PosY = inimigo4_tile.y * TILE_SIZE  + 5
					txt.position = Vector2(PosX, PosY)
					txt.set_text(player_dano, 0)
					add_child(txt)
					inimigo4_hp = min(inimigo4_hp - player_dano, inimigo4_hp_max)
					$Inimigos4.get_node("HPBar").rect_size.x = TILE_SIZE * inimigo4_hp/inimigo4_hp_max
					if(inimigo4_hp == 0):
						var alma = Alma.new(self,Elementos.Ar,inimigo4_tile)
						almasChao.append(alma)
						$Inimigos4.visible = false
						inimigo4_morto = true
					blocked = true
				if !blocked:
					if player_tile.x > x:
						player.set_frame(1)
					if player_tile.x < x:
						player.set_frame(0)
					player_tile = Vector2(x, y)
					for alma in almasChao:
						if alma.tile.x == player_tile.x && alma.tile.y == player_tile.y:
							if almasColetadas.size() < 10:
								almasColetadas.append(alma)
								almasChao.erase(alma)
								alma.remove()
					atualiza_almas()
			Tile.Escada:
					get_tree().change_scene("res://Cenas/Menu.tscn")

		if turnos>0:
			if almaAtiva == Elementos.Agua:
				turnos = turnos - 1
				if player_hp < player_hp_max:
					var regen = (player_hp_max - player_hp)/5
					if regen< 1:
						regen = 1
					var txt = LabelScene.instance()
					var PosX = player_tile.x * TILE_SIZE 
					var PosY = player_tile.y * TILE_SIZE  + 5
					txt.position = Vector2(PosX, PosY)
					txt.set_text(regen, 3)
					add_child(txt)
					player_hp = player_hp + regen
				if player_hp > player_hp_max:
					player_hp = player_hp_max
				$UI/HP.rect_size.x = 40 * player_hp/player_hp_max
		else:
			$UI/UiPlayer.set_frame(0)
		call_deferred("atualiza")

func atualiza():
	player.position = player_tile *  TILE_SIZE
	var player_centro = Vector2((player_tile.x + 0.5) * TILE_SIZE,(player_tile.y + 0.5) * TILE_SIZE)
	var space_state = get_world_2d().direct_space_state

func atualiza_almas():
	$UI/Alma1.set_frame(0)
	$UI/Alma2.set_frame(0)
	$UI/Alma3.set_frame(0)
	$UI/Alma4.set_frame(0)
	$UI/Alma5.set_frame(0)
	$UI/Alma6.set_frame(0)
	$UI/Alma7.set_frame(0)
	$UI/Alma8.set_frame(0)
	$UI/Alma9.set_frame(0)
	$UI/Alma10.set_frame(0)
	
	var temp = 0
	if almasColetadas.empty():
		print("RECARGA/ALMA")
		print("NULL")
		
	for alma in almasColetadas:
		if !almasColetadas.empty():
			print("RECARGA/ALMA")
			print(alma.Elemento)
		else:
			print("RECARGA/ALMA")
			print("NULL")
		print("RECARGA/temp")
		print(temp)
		match(temp):
			0:
				$UI/Alma1.set_frame(alma.Elemento + 1)
				temp = temp + 1
			1:
				print("Entrou")
				$UI/Alma2.set_frame(alma.Elemento + 1)
				print($UI/Alma2.get_frame())
				temp = temp + 1
			2:
				$UI/Alma3.set_frame(alma.Elemento + 1)
				temp = temp + 1
			3:
				$UI/Alma4.set_frame(alma.Elemento + 1)
				temp = temp + 1
			4:
				$UI/Alma5.set_frame(alma.Elemento + 1)
				temp = temp + 1
			5:
				$UI/Alma6.set_frame(alma.Elemento + 1)
				temp = temp + 1
			6:
				$UI/Alma7.set_frame(alma.Elemento + 1)
				temp = temp + 1
			7:
				$UI/Alma8.set_frame(alma.Elemento + 1)
				temp = temp + 1
			8:
				$UI/Alma9.set_frame(alma.Elemento + 1)
				temp = temp + 1
			9:
				$UI/Alma10.set_frame(alma.Elemento + 1)
				temp = temp + 1
				 
				