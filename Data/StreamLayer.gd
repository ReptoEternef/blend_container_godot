@tool
extends Resource

class_name StreamLayer

var stream_layer: AudioStream
#var layer_region: BcRegion
#var blend_container: BlendContainer
@export var min_value: float
@export var max_value: float
@export var fade_in_range: float
@export var fade_out_range: float
@export var file_name: String
var index: int
#var track

func _ready():
	print('Stream Layer ready')

func get_range() -> float:
	#print('get range')
	return max_value - min_value

func set_range(min_value: float, max_value: float, fade_in_length: float, fade_out_length: float):
	#print('set range')
	self.min_value = min_value
	self.max_value = max_value
	self.fade_in_range = fade_in_length
	self.fade_out_range = fade_out_length

func in_fade_in(value: float) -> bool:
	var fade_in_abs = get_range() * (fade_in_range / 100.0)
	return value >= min_value and value <= (min_value + fade_in_abs)

func in_fade_out(value: float) -> bool:
	var fade_out_abs = get_range() * (fade_out_range / 100.0)
	return value >= (max_value - fade_out_abs) and value <= max_value

func in_fade(value) -> Array:
	if self.in_fade_in(value):
		return [true, 'fade_in']
	elif in_fade_out(value):
		return [true, 'fade_out']
	else:
		return [false, '']


func calc_fade_volume(fade_type: String, value: float, previous_value: float):
	if fade_type == 'fade_in':
		var fade_in_abs = get_range() * (fade_in_range / 100.0)
		if fade_in_abs > 0:
			return clamp((value - min_value) / fade_in_abs * 100.0, 0.0, 100.0)
		else:
			return 100.0
	elif fade_type == 'fade_out':
		var fade_out_abs = get_range() * (fade_out_range / 100.0)
		if fade_out_abs > 0:
			return clamp((max_value - value) / fade_out_abs * 100.0, 0.0, 100.0)
		else:
			return 100.0
