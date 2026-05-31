@tool
extends VBoxContainer

## Corresponds to an AudioStreamPlayer (or an actual BlendContainer node)
class_name BcTracksContainer
var tracks: Array[BcTrack]
const TRACK_HEIGHT = 170
var available_rtpcs: Array[RTPC]
var blend_container: BlendContainer

func _ready() -> void:
	pass

func add_track(bc: BlendContainer) -> void:
	var track = BcTrack.new()
	track.available_rtpcs = available_rtpcs
	track.blend_container = bc
	add_child(track)
	tracks.append(track)

func remove_track(track: Node) -> void:
	track.queue_free()

func clear_tracks() -> void:
	for track in tracks:
		for child in track.get_children():
			child.free()
		track.free()
	tracks.clear()


func init_regions(bc: BlendContainer):
	blend_container = bc
	var stream_layers = blend_container.stream_layers
	#print('--- INIT REGION ---')
	for layer in stream_layers:
		tracks[0].add_region(layer.file_name, layer.min_value, layer.max_value, layer)
	
	if stream_layers.size() < 1 and blend_container.debug == true:
		print('debug')
		tracks[0].add_region('debug region', 0.0, 50.0, StreamLayer.new())
