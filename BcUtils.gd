extends Node

class_name BcUtils

# GLOBAL AUDIO FUNCTIONS

## Initialise les volumes de chaque layer à partir des sliders.
## [param player] le lecteur audio
## [param sliders] tableau de sliders correspondant aux layers
static func init_volumes(player, sliders: Array):
	for i in player.stream.get_stream_count():
		# make sure we have enough sliders for the amount of streams
		if i < sliders.size():
			var curr_value = sliders[i].value
			player.stream.set_sync_stream_volume(i, to_db(curr_value))
		else:
			print('not enough streams')

## Convertit une valeur de slider (0-100) en décibels
static func to_db(value: float):
	var db = lerp(-40.0, 0.0, sqrt(value / 100.0))
	if value == 0:
		db = -80
	return db

static func set_layer_volume(slider_value: float, layer: int, player):
	var db = AudioManager.to_db(slider_value)
	player.stream.set_sync_stream_volume(layer, db)

static func set_stream_volume(player, db):
	player.stream.volume_db(db)
