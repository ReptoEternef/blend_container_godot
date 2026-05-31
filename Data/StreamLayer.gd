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
	#print('calc in')
	if value <= (self.min_value + self.fade_in_range) and value >= self.min_value:
		#print('fade IN range at ', value)
		return true
	return false

func in_fade_out(value) -> bool:
	#print('calc out')
	if value >= (self.max_value - self.fade_out_range) and value <= self.max_value:
		#print('fade OUT range at ', value)
		return true
	return false

func in_fade(value) -> Array:
	#print('in fade')
	if self.in_fade_in(value):
		return [true, 'fade_in']
	elif in_fade_out(value):
		return [true, 'fade_out']
	else:
		return [false, '']

func calc_fade_volume(fade_type: String, value: float, previous_value: float):
	#print('calc fade')
	if fade_type == 'fade_in':
		if self.fade_in_range > 0:
			var min_fade_end = self.min_value + self.fade_in_range
			return (value - self.min_value) / (min_fade_end - self.min_value) * 100
		elif value <= 0:
			return 100
		elif value > previous_value:
			print(value, ' / ', self.min_value)
			return 100
		elif value < previous_value:
			print(value, ' / ', self.min_value)
			return 0
	elif fade_type == 'fade_out':
		if self.fade_out_range > 0:
			var min_fade_start = self.max_value - self.fade_out_range
			return (value - self.max_value) / (min_fade_start - self.max_value) * 100
		elif value >= 100:
			return 100
		elif value > previous_value:
			print(value, ' / ', self.min_value)
			return 0
		elif value < previous_value:
			print(value, ' / ', self.min_value)
			return 100
