@tool
extends AudioStreamPlayer

class_name BlendContainer

var main_stream: AudioStreamSynchronized
@export var stream_layers: Array[StreamLayer] = []
@export var rtpc: Array[RTPC]
var selected_rtpcs: Dictionary = {}

var debug: bool = true

func _ready() -> void:
	main_stream = self.stream
	init_layers()


func _on_button_button_up() -> void:
	self.play()


func update_blend(value: float, rtpc_label: String) -> void:
	#print(value)
	var rtpc = get_rtpc(rtpc_label)
	for layer in stream_layers:
		if is_in_range(layer, value):
			main_stream.set_sync_stream_volume(layer.index, BcUtils.to_db(100))
			
			#var fade_result = layer.in_fade(value)
			#if fade_result[0]:
				#print('play sound')
				#var fade_value = layer.calc_fade_volume(fade_result[1], value, rtpc.previous_value)
				#main_stream.set_sync_stream_volume(layer.index, BcUtils.to_db(fade_value))
		else:
			main_stream.set_sync_stream_volume(layer.index, BcUtils.to_db(0))
	rtpc.previous_value = value

func is_in_range(layer: StreamLayer, value: float) -> bool:
	#print(layer.max_value)
	if value >= layer.min_value and value <= layer.max_value:
		#print(layer.file_name, ' is in range from ', layer.min_value, ' to ', layer.max_value, '. Value : ', value)
		return true
	else:
		return false

func get_rtpc(label: String) -> RTPC:
	for r in rtpc:
		if r.label == label:
			return r
	return null

func init_layers():
	#print('-- INIT LAYERS --')
	#print(stream_layers[0].min_value)
	if main_stream == null:
		#print('all empty')
		return
	var layers_amnt = main_stream.get_stream_count()
	var new_layers: Array[StreamLayer] = []
	new_layers.resize(layers_amnt)

	for i in layers_amnt:
		var loop_layer = main_stream.get_sync_stream(i)

		if loop_layer == null:
			new_layers[i] = null
			continue

		var loop_layer_file_name = loop_layer.resource_path.get_file()

		# Cherche si ce fichier existait déjà dans l'ancien tableau
		var existing: StreamLayer = null
		for old_layer in stream_layers:
			if old_layer != null and old_layer.file_name == loop_layer_file_name:
				existing = old_layer
				break

		if existing != null:
			existing.index = i  # l'index a pu changer
			new_layers[i] = existing
		else:
			var new_layer = StreamLayer.new()
			new_layer.stream_layer = loop_layer
			#new_layer.blend_container = self
			new_layer.index = i
			new_layer.file_name = loop_layer_file_name

			# useless now
			#if i < stream_ranges.size():
				#new_layer.set_range(stream_ranges[i][0], stream_ranges[i][1], stream_ranges[i][2], stream_ranges[i][3])
			#else:
				#new_layer.set_range(0, 100, 0, 0)

			main_stream.set_sync_stream_volume(i, -80)
			new_layers[i] = new_layer

	stream_layers = new_layers


func get_layers_array() -> Array:
	var layers_array = []
	for i in main_stream.get_stream_count():
		var bs = StreamLayer.new()
		layers_array.append(bs)
	return layers_array

#func compare_layer_init():
	
