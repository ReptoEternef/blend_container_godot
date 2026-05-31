@tool
extends EditorPlugin

var dock
var dock_scene

var tracks_container: BcTracksContainer
var tracks: Array[BcTrack]

var blend_container: BlendContainer

func _enable_plugin() -> void:
	var selection = get_editor_interface().get_selection()
	
	if not selection.selection_changed.is_connected(_on_selection_changed):
		selection.selection_changed.connect(_on_selection_changed)
	
	_on_selection_changed()


func _disable_plugin() -> void:
	var selection = get_editor_interface().get_selection()
	
	if selection.selection_changed.is_connected(_on_selection_changed):
		selection.selection_changed.disconnect(_on_selection_changed)


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	# Load the dock scene and instantiate it.
	dock_scene = preload("res://addons/blend_container/UI/bc_scene.tscn").instantiate()

	# Create the dock and add the loaded scene to it.
	dock = EditorDock.new()
	dock.add_child(dock_scene)

	dock.title = "My Dock"

	# Note that LEFT_UL means the left of the editor, upper-left dock.
	dock.default_slot = DOCK_SLOT_LEFT_UL

	# Allow the dock to be on the left or right of the editor, and to be made floating.
	dock.available_layouts = EditorDock.DOCK_LAYOUT_VERTICAL | EditorDock.DOCK_LAYOUT_FLOATING

	add_dock(dock)
	
	var selection = get_editor_interface().get_selection()
	selection.selection_changed.connect(_on_selection_changed)



func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_dock(dock)
	# Erase the control from the memory.
	dock.queue_free()


func _on_selection_changed():
	var selected_nodes = get_editor_interface().get_selection().get_selected_nodes()
	if selected_nodes.is_empty():
		return
	var node = selected_nodes[0]
	if node is BlendContainer:
		#print('Load UI and logic')
		get_container_UI()
		get_container_logic(node)
	elif tracks_container:
		tracks_container.clear_tracks()
		

func get_container_logic(bc_node: BlendContainer):
	if bc_node.stream is AudioStreamSynchronized:
		blend_container = bc_node
		#print(blend_container.stream_layers[0].min_value)
		blend_container.init_layers()
		
		tracks_container.clear_tracks()
		if blend_container.rtpc.size() > 0:
			tracks_container.available_rtpcs = blend_container.rtpc
			tracks_container.add_track(blend_container)
			tracks = tracks_container.tracks
			tracks_container.init_regions(blend_container)
		else:
			push_warning("You need RTPCs setup")
	else:
		push_warning('Stream type must be Synchronized')


	#print('PLAYER : ', blend_container, ' / MAIN STREAM : ', main_stream, ' / LAYERS : ', stream_layers)

func get_container_UI():
	var plugin_children = dock_scene.get_children()
	for i in plugin_children.size():
		if plugin_children[i] is BcTracksContainer:
			tracks_container = plugin_children[i]
			#print(tracks_container.tracks)

func get_stream_layers(main_stream: AudioStreamSynchronized) -> Array:
	var layers = []
	for i in main_stream.stream_count:
		layers.append(main_stream.get_sync_stream(i))
	return layers
