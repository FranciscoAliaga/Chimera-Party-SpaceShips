extends Node2D

var Player = preload("res://games/FlowerLab/Scenes/Player.tscn")

onready var Players = $Players
var players

onready var gameplay_screen = get_node("GUI/MarginContainer/HBoxContainer/VBoxContainer3/gameplay")

func _ready():
	
	Party.load_test()
	players = Party.get_players()
	for i in range(players.size()):
		if players[i].color != -1:
			_alive_players.append(i)
			var player_inst = Player.instance()
			$Players.add_child(player_inst)
			player_inst.init(i, players[i].color)
	var player_num = Players.get_child_count()
	for i in range(player_num):
		Players.get_child(i).global_position = \
			$Positions.get_child(i).global_position
	
	$EndTimer.connect("timeout", self, "on_timeout")
	$EndTimer.start()


func _on_players_death():
	$EndTimer.stop()
	emit_signal("stop_gameplay_music")
	#wait a bit and then call _on_game_finish()
	pass

func _on_game_finish():
	$EndTimer.stop()
	# show gamescores
	
	var end_scores = [0, 0, 0, 0]
	for i in end_scores.size():
		end_scores[i]=_gameplay_scores[i]
	Party.end_game([end_scores])
#	Party.end_game([100, 0, 50, 0])
	pass # Replace with function body.

	
func _physics_process(_delta):
	
	pass
	# warning-ignore:shadowed_variable
#	var players = Players.get_children()
#	players.sort_custom(self, "sort_by_y")
#	for i in range(players.size()):
#		players[i].z_index = i
#
#func sort_by_y(a, b):
#	return a.position.y < b.position.y
#

## Scoring

var _alive_players = []
var _gameplay_scores = {-1:0,0:0,1:0,2:0,3:0}
signal score_changed
signal all_players_died

func _set_score(i,score):
	var new_score =max(score,0) 
	_gameplay_scores[i] = new_score
	emit_signal("score_changed",i,new_score)

func _sum_score(i,score):
	_set_score(i,score+_gameplay_scores[i])

signal player_died(i)
func _on_player_death(i):
	if _alive_players.size()==1:
		emit_signal("all_players_died",_alive_players[0])
		_show_players_and_winner(_alive_players[0])
		$Timer.wait_time=2
		$Timer.start()
	
	var target = _alive_players.find(i)
	if target==-1:
		push_warning("tried to remove a non alive player")
		return
	emit_signal("player_died",i)
	_sum_score(i,-5)
	_alive_players.remove(target)
	
	if _alive_players.size()==1:
		var indice = _alive_players[0]
		_sum_score(indice,20)
		return
	
	for j in _alive_players:
		_sum_score(j,10)

func _on_player_score_growth(i,score):
	_sum_score(i,score)

func _end_game():
	var final_scores = []
	for player_index in range(0,4):
		final_scores.append(_gameplay_scores[player_index])
	Party.end_game(final_scores)

func _show_players_and_winner(winner):
	var spaces = "                "
	
	var mensaje1 = ""
	for player_index in range(0,4):
		emit_signal("score_changed",player_index,_gameplay_scores[player_index])
		if player_index!= winner:
			mensaje1+= spaces +  "player " + str(player_index+1) +": " + str(_gameplay_scores[player_index]) + "\n"
		#else:
		#	mensaje1+= "player " + str(player_index+1) +": " + str(_gameplay_scores[player_index]) +"!!! <- Winner \n"
	var winner_message= spaces + "player "+ str(winner+1) + ": " + str(_gameplay_scores[winner])
	emit_signal("final_score",mensaje1,winner_message)

signal final_score(players,winner)

## API
#
#  Los colores disponibles son verde, rojo, amarillo, azul
#
#  Party.get_players(): retorna los jugadores actuales, cada jugador se
#  representa como un diccionario {color, points}
#  (color es un índice de 0 a 3, points es un entero)
#
#  Party.end_game(points): indica que la partida terminó y envía los
#  puntajes. El formato de los puntajes debe ser
#  [score_p0, score_p1, score_p2, score_p3]
#
#  Party.get_color_name(index): entrega el nombre del color
#
#  Party.available_colors: Entrega los colores disponibles
#
#  Party.game_type: Entrega el tipo de juego solicitado, los valores posibles son:
#  ALL_FOR_ALL = 0
#  ONE_VS_TWO = 1
#  ONE_VS_TREE = 2
#  TWO_VS_TWO = 3
#
#  Party.groups: Es un array que contiene arrays indicando los grupos.
#  Un ALL_FOR_ALL tendrá solo un elemento con un array conteniendo a todos
#  los jugadores actuales.
#
#  Debe notarse que solo los jugadores que tienen un color son los que
#  están jugando, puede que esté jugando solo el jugador 1 y 2 y no el 0 y 3
