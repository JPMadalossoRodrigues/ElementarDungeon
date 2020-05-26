extends Node2D

const EnemyScene = preload("res://Cenas/Inimigos.tscn")
const AlmaScene = preload("res://Cenas/Almas.tscn")
const LabelScene = preload("res://Cenas/Label.tscn")

const TILE_SIZE = 32
const LEVEL_SIZE = [Vector2(30,30), Vector2(35,35), Vector2(40,40), Vector2(45,45), Vector2(50,50)]
const LEVEL_ROOM = [5,7,9,12,15]
const LEVEL_ENEMY = [5,8,12,18,26]
const MIN_ROOM_SIZE = 5
const MAX_ROOM_SIZE = 10
const CENARIOS_SIZE = 1

enum Tile { Parede, Chao, Porta, Pedra, Escada }
enum Elementos { Terra, Agua, Ar, Fogo}

onready var tile_map = $Mapa
onready var visibilidade_map = $Visibilidade
onready var fog_map = $FOG
onready var player = $Player


var level_atual = 1
var cenario_atual = 0
var level_size
var mapa = []
var salas = []
var inimigos = []
var almasChao = []
var almasColetadas = []
var almaAtiva
var turnos = 0

var enemy_pathfinding

var player_tile
var player_hp_max = 100
var player_hp = player_hp_max
var player_dano = 10
var player_esquiva = 20
var player_morto = true

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

class Inimigo extends Reference:
	var sprite_node
	var tile
	var elemento
	var hp_full
	var hp_atual
	var dano
	var esquiva
	var dead = false
	
	func _init(_game, _elemento,_tile):
		tile = _tile
		sprite_node = EnemyScene.instance()
		sprite_node.frame = _elemento + 8 * _game.cenario_atual
		sprite_node.position = tile * TILE_SIZE
		_game.add_child(sprite_node)
		
		match _elemento:
			0:
				hp_full = 35
				hp_atual = hp_full
				dano = 5
				esquiva = 0
				elemento = Elementos.Terra
			1:
				hp_full = 30
				hp_atual = hp_full
				dano = 5
				esquiva = 15
				elemento = Elementos.Agua
			2:
				hp_full = 30
				hp_atual = hp_full
				dano = 3
				esquiva = 20
				elemento = Elementos.Ar
			3:
				hp_full = 25
				hp_atual = hp_full
				dano = 7
				esquiva = 15
				elemento = Elementos.Fogo
		_game.add_child(sprite_node)
	
	func remove():
		sprite_node.queue_free()
	
	func take_damage(_game, _damage):
		if dead:
			return
		hp_atual = max(0, hp_atual -  _damage)
		sprite_node.get_node("HPBar").rect_size.x = TILE_SIZE * hp_atual/hp_full
		if hp_atual == 0:
			dead = true
			var alma = Alma.new(_game,elemento,tile)
			_game.almasChao.append(alma)
	
	func damage_player(dmg, _game):
		var temp_esquiva = randi()%100
		if _game.turnos>0:
			if _game.almaAtiva == Elementos.Ar:
				temp_esquiva = temp_esquiva - 10
				_game.turnos = _game.turnos - 1
		if temp_esquiva > _game.player_esquiva:
			var dano = dmg
			if _game.turnos>0:
				if _game.almaAtiva == Elementos.Terra:
					_game.turnos = _game.turnos - 1
					dano = dmg/ 2
			var txt = LabelScene.instance()
			var PosX = _game.player_tile.x * TILE_SIZE 
			var PosY = _game.player_tile.y * TILE_SIZE  + 5
			txt.position = Vector2(PosX, PosY)
			txt.set_text(dano, 1)
			_game.add_child(txt)
			_game.player_hp = max(0 , _game.player_hp-dano)
			_game.get_node('UI/HP').rect_size.x = 148 * _game.player_hp/_game.player_hp_max
			if _game.player_hp == 0:
				_game.player_morto = true
				_game.get_node('UI/Lose').visible = true
			if _game.turnos>0:
				if _game.almaAtiva == Elementos.Fogo:
					var temp = dano/5
					if temp > 1:
						temp = 1
					take_damage(self,temp)
					_game.turnos = _game.turnos - 1
		else:
			var txt = LabelScene.instance()
			var PosX = _game.player_tile.x * TILE_SIZE 
			var PosY = _game.player_tile.y * TILE_SIZE  + 5
			txt.position = Vector2(PosX, PosY)
			txt.set_text("miss", 1)
			_game.add_child(txt)
	
	func act(_game):
		if !sprite_node.visible:
			var dir = randi()%4
			match dir:
				0:
					if _game.mapa[tile.x +1][tile.y] == Tile.Chao:
						tile = Vector2(tile.x + 1,tile.y)
						sprite_node.frame = elemento*2 +8 * _game.cenario_atual
				1:
					if _game.mapa[tile.x -1][tile.y] == Tile.Chao:
						tile = Vector2(tile.x - 1,tile.y)
						sprite_node.frame = elemento*2 + 1 + 8 * _game.cenario_atual
				2:
					if _game.mapa[tile.x][tile.y+1] == Tile.Chao:
						tile = Vector2(tile.x,tile.y + 1)
				3:
					if _game.mapa[tile.x][tile.y-1] == Tile.Chao:
						tile = Vector2(tile.x,tile.y - 1)
			return
		var my_point = _game.enemy_pathfinding.get_closest_point(Vector3(tile.x, tile.y, 0))
		var player_point = _game.enemy_pathfinding.get_closest_point(Vector3(_game.player_tile.x, _game.player_tile.y, 0))
		var path = _game.enemy_pathfinding.get_point_path(my_point,player_point)
		if path:
			if path.size() > 1:
				var move_tile = Vector2(path[1].x,path[1].y)
				if move_tile == _game.player_tile:
					damage_player(dano, _game)
				else:
					var block = false
					for enemy in _game.inimigos:
						if enemy.tile == move_tile:
							block = true
							break
					if !block:
						if tile.x < move_tile.x:
							sprite_node.frame = elemento*2 +8 * _game.cenario_atual
						elif tile.x>move_tile.x:
							sprite_node.frame = elemento*2 + 1 + 8 * _game.cenario_atual
						 
						tile = move_tile

func _ready():
	OS.set_window_size(Vector2(1280,720))
	randomize()
	cria_level()

func _input(event):
	if !event.is_pressed():
		return
	if event.is_action("ui_end"):
		if!$UI/Pause.visible:
			$UI/Pause.visible = true
			player_morto = true
		else:
			$UI/Pause.visible = false
			player_morto = false
	if event.is_action("ui_enter")  && $UI/Carta.visible:
		player_morto = false
		$UI/Carta.visible = false
	if(!player_morto):
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
	if(!player_morto):
		
		var x = player_tile.x + _x
		var y = player_tile.y + _y
	
		var tile_type = Tile.Pedra
	
		if x >= 0 && x < level_size.x && y >= 0 && y < level_size.y:
			tile_type = mapa[x][y]
	
		match tile_type:
			Tile.Chao:
				var blocked = false
				for enemy in inimigos:
					if enemy.tile.x == x && enemy.tile.y == y:
						var dano = player_dano
						var esquiva = randi()%100
						var IsCrit = 1
						if esquiva > enemy.esquiva:
							if !almasColetadas.empty():
								match enemy.elemento:
									Elementos.Terra:
										if almasColetadas[0].Elemento == Elementos.Fogo:
											dano = dano *1.5
											IsCrit = 2
									Elementos.Fogo:
										if almasColetadas[0].Elemento == Elementos.Agua:
											dano = dano *1.5
											IsCrit = 2
									Elementos.Agua:
										if almasColetadas[0].Elemento == Elementos.Ar:
											dano = dano *1.5
											IsCrit = 2
									Elementos.Ar:
										if almasColetadas[0].Elemento == Elementos.Terra:
											dano = dano *1.5
											IsCrit = 2
							var txt = LabelScene.instance()
							var PosX = enemy.tile.x * TILE_SIZE 
							var PosY = enemy.tile.y * TILE_SIZE  + 5
							txt.position = Vector2(PosX, PosY)
							txt.set_text(dano, IsCrit)
							add_child(txt)
							enemy.take_damage(self,dano)
							if enemy.dead:
								enemy.remove()
								inimigos.erase(enemy)
						else:
							var txt = LabelScene.instance()
							var PosX = enemy.tile.x * TILE_SIZE 
							var PosY = enemy.tile.y * TILE_SIZE  + 5
							txt.position = Vector2(PosX, PosY)
							txt.set_text("miss", IsCrit)
							add_child(txt)
						blocked = true
						break
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
			Tile.Porta:
				set_tile(x, y, Tile.Chao)
			Tile.Escada:
					if(level_atual == 5):
						level_atual = 1
						cenario_atual += 1
					else:
						level_atual +=1
					if level_atual < LEVEL_SIZE.size() && cenario_atual < CENARIOS_SIZE:
						cria_level()
					else:
							player_morto = true
							$UI/Win.visible = true
		for enemy in inimigos:
					enemy.act(self)
		
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
				$UI/HP.rect_size.x = 148 * player_hp/player_hp_max
		else:
			$UI/UiPlayer.set_frame(0)
		call_deferred("atualiza")

func atualiza():
	player.position = player_tile *  TILE_SIZE
	var player_centro = Vector2((player_tile.x + 0.5) * TILE_SIZE,(player_tile.y + 0.5) * TILE_SIZE)
	var space_state = get_world_2d().direct_space_state
	
	for x in range (level_size.x):
		for y in range(level_size.y):
			if visibilidade_map.get_cell(x,y) == 0:
				var x_dir = 1 if x < player_tile.x else -1 
				var y_dir = 1 if y < player_tile.y else -1
				var ponto_teste = Vector2((x + 0.5) * TILE_SIZE,(y + 0.5) * TILE_SIZE) + Vector2(x_dir,y_dir) * TILE_SIZE/2
				
				var ocultar = space_state.intersect_ray(player_centro, ponto_teste)
				if !ocultar || (ocultar.position - ponto_teste).length() < 1:
					visibilidade_map.set_cell(x,y,-1)
	for x in range (level_size.x):
		for y in range(level_size.y):
			var x_dir = 1 if x < player_tile.x else -1 
			var y_dir = 1 if y < player_tile.y else -1
			var ponto_teste = Vector2((x + 0.5) * TILE_SIZE,(y + 0.5) * TILE_SIZE) + Vector2(x_dir,y_dir) * TILE_SIZE/2
				
			var ocultar = space_state.intersect_ray(player_centro, ponto_teste)
			if !ocultar || (ocultar.position - ponto_teste).length() < 1:
				fog_map.set_cell(x,y,-1)
			else:
				fog_map.set_cell(x,y,0)
	for enemy in inimigos:
		enemy.sprite_node.position = enemy.tile * TILE_SIZE
		var enemy_center = Vector2((enemy.tile.x+ 0.5) * TILE_SIZE,(enemy.tile.y + 0.5) * TILE_SIZE)
		var oculto = space_state.intersect_ray(player_centro, enemy_center)
		if !oculto:
			enemy.sprite_node.visible = true
		else:
			enemy.sprite_node.visible = false

func cria_level():
	salas.clear()
	mapa.clear()
	tile_map.clear()
	
	atualiza_almas()
	
	for enemy in inimigos:
		enemy.remove()
	inimigos.clear()
	
	enemy_pathfinding = AStar.new()
	
	level_size = LEVEL_SIZE[level_atual]
	for x in range(level_size.x):
		mapa.append([])
		for y in range(level_size.y):
			mapa[x].append(Tile.Pedra)
			tile_map.set_cell(x,y,Tile.Pedra + 5 * cenario_atual)
			visibilidade_map.set_cell(x,y,0)
	
	var tiles_livres = [Rect2(Vector2(2,2), level_size - Vector2(4,4))]
	var num_salas = LEVEL_ROOM[level_atual]
# warning-ignore:unused_variable
# warning-ignore:unused_variable
	for i in range(num_salas):
		add_sala(tiles_livres)
		if tiles_livres.empty():
			break
	
	conecta_salas()
	
	var sala_inicial = salas.front()
	var player_x = sala_inicial.position.x + 1 + randi() % int(sala_inicial.size.x - 2)
	var player_y = sala_inicial.position.y + 1 + randi() % int(sala_inicial.size.y - 2)
	player_tile = Vector2(player_x,player_y)
	call_deferred("atualiza")
	
	var sala_final = salas.back()
	var escada_x = sala_final.position.x + 1 + randi() % int(sala_final.size.x - 2)
	var escada_y = sala_final.position.y + 1 + randi() % int(sala_final.size.y - 2)
	set_tile(escada_x, escada_y, Tile.Escada)
	
	var num_enemies = LEVEL_ENEMY[level_atual]
	for i in range(num_enemies):
		var room = salas[1 + randi()% (salas.size()-1)]
		var x  = room.position.x + 1 + randi()% int (room.size.x -2) 
		var y  = room.position.y + 1 + randi()% int (room.size.y -2) 
		
		var blocked = false
		for enemy in inimigos:
			if enemy.tile.x == x && enemy.tile.y == y:
				blocked = true
		if !blocked:
			var enemy =  Inimigo.new(self,randi()%4,Vector2(x,y))
			inimigos.append(enemy)

func add_sala(_tiles_livres):
	var regiao = _tiles_livres[randi()%_tiles_livres.size()]
	
	var size_x = MIN_ROOM_SIZE
	if regiao.size.x > MIN_ROOM_SIZE:
		size_x += randi()%int(regiao.size.x - MIN_ROOM_SIZE)
	size_x = min(size_x, MAX_ROOM_SIZE)
	var size_y = MIN_ROOM_SIZE
	if regiao.size.y > MIN_ROOM_SIZE:
		size_y += randi()% int(regiao.size.y - MIN_ROOM_SIZE)
	size_y = min(size_y, MAX_ROOM_SIZE)
	
	var pos_x = regiao.position.x
	if regiao.size.x > size_x:
		pos_x += randi() % int(regiao.size.x - size_x)
	var pos_y = regiao.position.y
	if regiao.size.y > size_y:
		pos_y += randi() % int(regiao.size.y - size_y)
	
	var sala = Rect2(pos_x, pos_y, size_x, size_y)
	salas.append(sala)
	
	for x in range(pos_x, pos_x + size_x):
		set_tile(x, pos_y, Tile.Parede)
		set_tile(x, pos_y + size_y - 1, Tile.Parede)
	for y in range(pos_y + 1, pos_y + size_y - 1):
		set_tile(pos_x, y, Tile.Parede)
		set_tile(pos_x + size_x - 1, y, Tile.Parede)
		for x in range(pos_x + 1, pos_x + size_x - 1):
			set_tile(x,y, Tile.Chao)
	
	cut_region(_tiles_livres, sala)

func conecta_salas():
		
	var grafo_preto = AStar.new()
	var ponto_id = 0
	
	for x in range(level_size.x):
		for y in range(level_size.y):
			if mapa[x][y] == Tile.Pedra:
				grafo_preto.add_point(ponto_id, Vector3(x,y,0))
				if x > 0 && mapa[x-1][y] == Tile.Pedra:
					var ponto_esq = grafo_preto.get_closest_point(Vector3(x-1,y,0))
					grafo_preto.connect_points(ponto_id, ponto_esq)
				if y > 0 && mapa[x][y-1] == Tile.Pedra:
					var ponto_baixo = grafo_preto.get_closest_point(Vector3(x,y-1,0))
					grafo_preto.connect_points(ponto_id, ponto_baixo)
				ponto_id += 1
	
	var grafo_salas = AStar.new()
	ponto_id = 0
	for sala in salas:
		var centro = sala.position + sala.size/2
		grafo_salas.add_point(ponto_id, Vector3(centro.x,centro.y,0))
		ponto_id +=1
	
	while !todos_conectados(grafo_salas):
		add_conexao(grafo_preto, grafo_salas)

func cut_region(_tiles_limpos, _regiao_removida):
	var regiao_apagada = []
	var regiao_adicionada = []
	
	for regiao in _tiles_limpos:
		if regiao.intersects(_regiao_removida):
			regiao_apagada.append(regiao)
			
			var borda_esq = _regiao_removida.position.x - regiao.position.x - 1
			var borda_dir = regiao.end.x - _regiao_removida.end.x - 1
			var borda_cima = _regiao_removida.position.y - regiao.position.y - 1
			var borda_baixo = regiao.end.y - _regiao_removida.end.y - 1
			
			if borda_esq >= MIN_ROOM_SIZE:
				regiao_adicionada.append(Rect2(regiao.position, Vector2(borda_esq, regiao.size.y)))
			if borda_dir >= MIN_ROOM_SIZE:
				regiao_adicionada.append(Rect2(Vector2(_regiao_removida.end.x + 1, regiao.position.y),Vector2(borda_dir, regiao.size.y)))
			if borda_cima >= MIN_ROOM_SIZE:
				regiao_adicionada.append(Rect2(regiao.position, Vector2(regiao.size.x, borda_cima)))
			if borda_baixo >= MIN_ROOM_SIZE:
				regiao_adicionada.append(Rect2(Vector2(regiao.position.x, _regiao_removida.end.y + 1),Vector2(regiao.size.x, borda_baixo)))
				
	for regiao in regiao_apagada:
		_tiles_limpos.erase(regiao)
	for regiao in regiao_adicionada:
		_tiles_limpos.append(regiao)

func set_tile(_x,_y,_tipo):
	mapa[_x][_y] = _tipo
	tile_map.set_cell(_x,_y, _tipo + 5 * cenario_atual)
	if _tipo == Tile.Chao:
		novo_caminho(Vector2(_x,_y))

func todos_conectados(_grafo):
	var pontos = _grafo.get_points()
	var inicio = pontos.pop_back()
	
	for ponto in pontos:
		var caminho = _grafo.get_point_path(inicio, ponto)
		if !caminho:
			return false
	return true

func add_conexao(_grafo_preto, _grafo_salas):
	var sala_inicial = ultimo_ponto_conectado(_grafo_salas)
	var sala_final = sala_mais_proxima_desconectada(_grafo_salas,sala_inicial)
	
	var porta_inicial = gera_porta(salas[sala_inicial])
	var porta_final = gera_porta(salas[sala_final])
	
	var inicio = _grafo_preto.get_closest_point(porta_inicial)

	var fim =  _grafo_preto.get_closest_point(porta_final)

	var caminho = _grafo_preto.get_point_path(inicio, fim)

	set_tile(porta_inicial.x, porta_inicial.y, Tile.Porta)
	set_tile(porta_final.x, porta_final.y, Tile.Porta)
	 
	for posicao in caminho:
		set_tile(posicao.x,posicao.y, Tile.Chao)
	
	if mapa[porta_inicial.x + 1][porta_inicial.y] != Tile.Porta && mapa[porta_inicial.x - 1][porta_inicial.y] != Tile.Porta && mapa[porta_inicial.x][porta_inicial.y + 1]  != Tile.Porta && mapa[porta_inicial.x][porta_inicial.y - 1]  != Tile.Porta:  
		set_tile(porta_inicial.x, porta_inicial.y, Tile.Porta)
	else:
		set_tile(porta_inicial.x, porta_inicial.y, Tile.Parede)
		
	if mapa[porta_final.x + 1][porta_final.y] != Tile.Porta && mapa[porta_final.x - 1][porta_final.y] != Tile.Porta && mapa[porta_final.x][porta_final.y + 1]  != Tile.Porta && mapa[porta_final.x][porta_final.y - 1]  != Tile.Porta:
		set_tile(porta_final.x, porta_final.y, Tile.Porta)
	else:
		set_tile(porta_final.x, porta_final.y, Tile.Parede)
		
	_grafo_salas.connect_points(sala_inicial, sala_final)

func ultimo_ponto_conectado(_grafo):
	var pontos = _grafo.get_points()
	var ultimo
	var conectados = []
	
	for ponto in pontos:
		var count = _grafo.get_point_connections(ponto).size()
		if !ultimo || count < ultimo:
			ultimo = count
			conectados = [ponto]
		elif count == ultimo:
			conectados.append(ponto)
	return conectados[randi()% conectados.size()]

func  sala_mais_proxima_desconectada(_grafo,_alvo):
	var posicao = _grafo.get_point_position(_alvo)
	var pontos = _grafo.get_points()
	
	var menor_distancia
	var conectados = []
	
	for ponto in pontos:
		if ponto == _alvo:
			continue
		
		var caminho = _grafo.get_point_path(ponto, _alvo)
		if caminho:
			continue
		
		var dist = (_grafo.get_point_position(ponto) - posicao).length()
		if !menor_distancia || dist < menor_distancia:
			menor_distancia = dist
			conectados = [ponto]
		elif dist == menor_distancia:
			conectados.append(ponto)
	
	return conectados[randi()% conectados.size()]

func gera_porta(_sala):
	var opcoes = []
	for x in range(_sala.position.x + 1, _sala.end.x - 2):
		opcoes.append(Vector3(x, _sala.position.y,0))
		opcoes.append(Vector3(x, _sala.end.y - 1,0))
	for y in range(_sala.position.y + 1, _sala.end.y - 2):
		opcoes.append(Vector3(_sala.position.x, y,0))
		opcoes.append(Vector3(_sala.end.x - 1, y ,0))
	return opcoes[randi()%opcoes.size()]

func novo_caminho(tile):
	var novo_ponto = enemy_pathfinding.get_available_point_id()
	enemy_pathfinding.add_point(novo_ponto, Vector3(tile.x,tile.y,0))
	var points_to_connect = []
	
	if tile.x > 0 && mapa[tile.x-1][tile.y] == Tile.Chao:
		points_to_connect.append(enemy_pathfinding.get_closest_point(Vector3(tile.x-1,tile.y,0)))
	if tile.y > 0 && mapa[tile.x][tile.y-1] == Tile.Chao:
		points_to_connect.append(enemy_pathfinding.get_closest_point(Vector3(tile.x,tile.y-1,0)))
	if tile.x < level_size.x - 1 && mapa[tile.x+1][tile.y] == Tile.Chao:
		points_to_connect.append(enemy_pathfinding.get_closest_point(Vector3(tile.x+1,tile.y,0)))
	if tile.x < level_size.y - 1 && mapa[tile.x][tile.y+1] == Tile.Chao:
		points_to_connect.append(enemy_pathfinding.get_closest_point(Vector3(tile.x,tile.y+1,0)))
	
	for points in points_to_connect:
		enemy_pathfinding.connect_points(points,novo_ponto)

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

func _on_Menu_button_down():
	get_tree().change_scene("res://Cenas/Menu.tscn")

func _on_Quit_button_down():
	get_tree().quit()
	
func _on_Voltar_button_down():
	$UI/Pause.visible = false
	player_morto = false