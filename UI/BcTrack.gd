@tool
class_name BcTrack
extends VBoxContainer

var track_name: String = "Track"
var volume: float = 1.0
var rtpc_parameter: RTPC = null
var available_rtpcs: Array[RTPC]
var blend_container: BlendContainer

const TRACK_HEIGHT = 170
const TOPBAR_HEIGHT = 40
const RULER_HEIGHT = 20
const REGIONS_HEIGHT = TRACK_HEIGHT - TOPBAR_HEIGHT - RULER_HEIGHT

var top_bar: PanelContainer
var regions_container: Control
var menu_button: MenuButton
var rtpc_button: MenuButton
var region_values: Label
var region_values_fallback = 'No region selected.'
var region_label: Label
var region_label_fallback = 'test'
var ruler: BcRuler

func _ready() -> void:
	var track_index = get_index()
	if blend_container.selected_rtpcs.has(track_index):
		rtpc_parameter = blend_container.selected_rtpcs[track_index]
	elif available_rtpcs.size() > 0:
		rtpc_parameter = available_rtpcs[0]
		blend_container.selected_rtpcs[track_index] = rtpc_parameter
	_build_ui()

func _build_ui() -> void:
	_build_top_bar()
	_build_regions_container()
	#_build_ruler()

func _build_top_bar() -> void:
	# create top bar
	top_bar = PanelContainer.new()
	top_bar.custom_minimum_size.y = TOPBAR_HEIGHT
	add_child(top_bar)
	
	# container to automatically display childs (flexbox row)
	var hbox = HBoxContainer.new()
	top_bar.add_child(hbox)
	
	# add menu button ------------------------------
	menu_button = MenuButton.new()
	menu_button.text = "☰"
	menu_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hbox.add_child(menu_button)
	
	var popup = menu_button.get_popup()
	popup.add_item("Rename", 0)
	popup.add_item("Delete", 1)
	popup.id_pressed.connect(_on_menu_item_selected)
	# add menu button ------------------------------
	
	# add RTPC button ------------------------------
	rtpc_button = MenuButton.new()
	rtpc_button.text = rtpc_parameter.label if rtpc_parameter else "RTPC"
	rtpc_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hbox.add_child(rtpc_button)
	
	var rtpc_popup = rtpc_button.get_popup()
	for i in range(available_rtpcs.size()):
		rtpc_popup.add_item(available_rtpcs[i].label, i)
	rtpc_popup.id_pressed.connect(_on_rtpc_selected)
	# add RTPC button ------------------------------
	
	var separator1 = VSeparator.new()
	hbox.add_child(separator1)
	
	# display region infos -------------------------
	region_values = Label.new()
	region_values.clip_text = true
	region_values.custom_minimum_size.x = 100
	region_values.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	region_values.text = region_values_fallback
	hbox.add_child(region_values)
	
	var separator2 = VSeparator.new()
	hbox.add_child(separator2)
	
	region_label = Label.new()
	region_label.text = region_label_fallback
	region_label.clip_text = true
	region_label.custom_minimum_size.x = 100
	region_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(region_label)
	# display region infos -------------------------


func _build_ruler() -> void:
	ruler = BcRuler.new()
	ruler.custom_minimum_size.y = RULER_HEIGHT
	ruler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(ruler)

func _build_regions_container() -> void:
	regions_container = Control.new()
	regions_container.custom_minimum_size = Vector2(0, REGIONS_HEIGHT)
	regions_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(regions_container)

func _on_menu_item_selected(id: int) -> void:
	match id:
		0: pass # Rename
		1: queue_free()

func _on_rtpc_selected(id: int) -> void:
	rtpc_parameter = available_rtpcs[id]
	rtpc_button.text = rtpc_parameter.label
	blend_container.selected_rtpcs[get_index()] = rtpc_parameter
	#ruler.rtpc = rtpc_parameter
	#ruler.queue_redraw()

func add_region(region_name: String, start_value: float, end_value: float, fade_in_range: float, fade_out_range: float, layer: StreamLayer) -> void:
	if is_nan(start_value):
		start_value = 0
	if end_value == 0:
		end_value = 10

	var region = BcRegion.new()
	region.parent_track = self
	region.position = Vector2(start_value, 0)
	region.size = Vector2(end_value, REGIONS_HEIGHT)
	region.region_name = region_name
	region.stream_layer = layer
	layer.min_value = start_value
	layer.max_value = end_value
	layer.fade_in_range = fade_in_range
	layer.fade_out_range = fade_out_range
	regions_container.add_child(region)
