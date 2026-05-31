@tool
extends Control

## Corresponds to a single Stream (or what I call a StreamLayer)
class_name BcRegion
var parent_track: BcTrack
var dragging_left = false
var dragging_right = false
var dragging_move = false
var panel_size
var panel_pos
var border_size = 15
var min_window_size = 30

var layer_start_rtpc: float
var layer_end_rtpc: float
var layer_start_percent: float
var layer_end_percent: float

var stream_layer: StreamLayer
var region_name: String
var bg_color: Color

# VARIABLES FOR FADES
var fade_in_px: float
var fade_out_px: float
var dragging_fade_in = false
var dragging_fade_out = false
var handle_hit_radius = 10.0

func _ready():
	custom_minimum_size.x = min_window_size
	tooltip_text = region_name
	bg_color = Color.from_hsv(randf(), 0.6, 0.8, 0.6)
	get_parent().resized.connect(apply_position_from_layer, CONNECT_ONE_SHOT)

func _draw():
	# Fond
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)
	# Bord
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE, false, 1.5)
	
	draw_string(
		ThemeDB.fallback_font,   # la font par défaut de Godot
		Vector2(8, size.y - 10), # position (x, y) — note que y c'est la baseline du texte
		region_name,      # le texte
		HORIZONTAL_ALIGNMENT_LEFT,
		size.x - 16,             # largeur max (-1 = infini)
		11,                      # taille de la font
		Color.WHITE
	)
	
	_draw_fades()

func _draw_fades():
	var fade_in_px  = percent_to_px(stream_layer.fade_in_range, size.x)
	var fade_out_px = percent_to_px(stream_layer.fade_out_range, size.x)

	var bottom_left  = Vector2(0, size.y)
	var bottom_right = Vector2(size.x, size.y)
	var fade_in_handle  = Vector2(fade_in_px, 0)
	var fade_out_handle = Vector2(size.x - fade_out_px, 0)

	draw_line(bottom_left, fade_in_handle, Color.WHITE, 1.5)
	draw_line(fade_out_handle, bottom_right, Color.WHITE, 1.5)
	draw_circle(fade_in_handle, 5.0, Color.WHITE)
	draw_circle(fade_out_handle, 5.0, Color.WHITE)


func _notification(what):
	if what == NOTIFICATION_RESIZED:
		if not is_inside_tree():
			return
		queue_redraw()

func apply_position_from_layer():
	var parent_width = get_parent_area_size().x
	position.x = (stream_layer.min_value / 100.0) * parent_width
	size.x = ((stream_layer.max_value - stream_layer.min_value) / 100.0) * parent_width

func update_region_data():
	if not is_inside_tree():
		return
	var layer_start_px = position.x
	var layer_end_px = layer_start_px + size.x
	
	layer_start_percent = px_to_percent(layer_start_px, get_parent_area_size().x)
	layer_end_percent = px_to_percent(layer_end_px, get_parent_area_size().x)
	stream_layer.min_value = layer_start_percent
	stream_layer.max_value = layer_end_percent
	
	layer_start_rtpc = percent_to_rtpc(stream_layer.min_value)
	layer_end_rtpc = percent_to_rtpc(stream_layer.max_value)
	
	stream_layer.emit_changed()
	EditorInterface.mark_scene_as_unsaved()
	
	update_topbar_position_infos()
	#print('START : ', stream_layer.min_value, ' / END : ', stream_layer.max_value)

func px_to_rtpc(raw_value) -> float:
	var to_percent = px_to_percent(raw_value, get_parent_area_size().x)
	#print(region_name, ' percent : ', to_percent)
	var to_rtpc = percent_to_rtpc(to_percent)
	#print(region_name, ' rtpc : ', to_rtpc)
	return to_rtpc

func px_to_percent(raw_value: float, parent_raw_size: float) -> float:
	#var parent_raw_size = get_parent_area_size().x
	var percent
	if raw_value > 0:
		percent = (100 * raw_value) / parent_raw_size
		if percent <= 0:
			percent = 0
		elif percent >= 100:
			percent = 100
	else:
		percent = 0
	return percent
	
func percent_to_px(percent: float, parent_raw_size: float) -> float:
	var raw_value
	if percent > 0:
		raw_value = (percent * parent_raw_size) / 100
		if raw_value <= 0:
			raw_value = 0
		elif raw_value >= parent_raw_size:
			raw_value = parent_raw_size
	else:
		raw_value = 0
	return raw_value

func percent_to_rtpc(x) -> float:
	if parent_track == null or parent_track.rtpc_parameter == null:
		return 0.0
	var rtpc = parent_track.rtpc_parameter
	var calc = rtpc.min_rtpc_value + (x / 100.0) * (rtpc.max_rtpc_value - rtpc.min_rtpc_value)
	return calc

func rtpc_to_percent(x) -> float:
	var rtpc = parent_track.rtpc_parameter
	var calc = (x - rtpc.min_rtpc_value) / (rtpc.max_rtpc_value - rtpc.min_rtpc_value) * 100
	return calc


func update_topbar_position_infos():
	#print('updates top bar : ', layer_start_rtpc, ' ; ', layer_end_rtpc)
	var values_text = "%.2f ; %.2f" % [layer_start_rtpc, layer_end_rtpc]
	parent_track.region_values.text = values_text
	parent_track.region_selector.text = region_name



func _gui_input(event: InputEvent) -> void:
	panel_size = self.get_rect().size
	panel_pos = self.get_rect().position
	
	# defines whether we move, resize or drag a fade handle
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			move_to_front()
		# fade handles are tested first so they take priority over the edges
		var handle = get_hovered_handle(event.position)
		if handle == "fade_in":
			dragging_fade_in = event.pressed
		elif handle == "fade_out":
			dragging_fade_out = event.pressed
		elif event.position.x < border_size:
			dragging_left = event.pressed
		elif event.position.x > (panel_size.x - border_size):
			dragging_right = event.pressed
		else:
			dragging_move = event.pressed
			update_topbar_position_infos()
	
	# changes cursor depending on drag type
	if event is InputEventMouseMotion:
		# fade handle hover takes priority over the edges
		var handle = get_hovered_handle(event.position)
		if handle != "" or dragging_fade_in or dragging_fade_out:
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		elif event.position.x < border_size or dragging_left:
			mouse_default_cursor_shape = Control.CURSOR_HSIZE
		elif event.position.x > (panel_size.x - border_size) or dragging_right:
			mouse_default_cursor_shape = Control.CURSOR_HSIZE
		elif dragging_move:
			mouse_default_cursor_shape = Control.CURSOR_DRAG
		elif not dragging_left and not dragging_right and not dragging_move:
			mouse_default_cursor_shape = Control.CURSOR_ARROW
	
	# drag the fade in handle (distance from the left edge)
	if event is InputEventMouseMotion and dragging_fade_in:
		var fade_in_px = clamp(event.position.x, 0, size.x - percent_to_px(stream_layer.fade_out_range, size.x))
		stream_layer.fade_in_range = px_to_percent(fade_in_px, size.x)
		stream_layer.emit_changed()
		queue_redraw()
	
	# drag the fade out handle (distance from the right edge)
	if event is InputEventMouseMotion and dragging_fade_out:
		var fade_out_px = clamp(size.x - event.position.x, 0, size.x - percent_to_px(stream_layer.fade_in_range, size.x))
		stream_layer.fade_out_range = px_to_percent(fade_out_px, size.x)
		stream_layer.emit_changed()
		queue_redraw()
	
	# change size and position to drag from the left side
	if event is InputEventMouseMotion and dragging_left:
		var mouse_x = get_global_mouse_position().x
		var left_edge = global_position.x
		var new_size = max(left_edge + size.x - mouse_x, min_window_size)
		var delta = size.x - new_size
		size.x = new_size
		position.x += delta
		position.x = clamp(position.x, 0, get_parent().size.x - size.x)
		update_region_data()
	
	# change size to drag from the right side
	if event is InputEventMouseMotion and dragging_right:
		var mouse_x = get_global_mouse_position().x
		var new_size = max(mouse_x - global_position.x, min_window_size)
		size.x = clamp(new_size, min_window_size, get_parent().size.x - position.x)
		update_region_data()
	
	# change position (x only) to move the region
	if event is InputEventMouseMotion and dragging_move:
		position.x += event.relative.x
		position.x = clamp(position.x, 0, get_parent().size.x - size.x)
		update_region_data()

func _input(event: InputEvent) -> void:
	# global safety net: if the left button is released anywhere, stop every drag
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		dragging_left = false
		dragging_right = false
		dragging_move = false
		dragging_fade_in = false
		dragging_fade_out = false

func get_hovered_handle(mouse_pos: Vector2) -> String:
	var fade_in_px  = percent_to_px(stream_layer.fade_in_range, size.x)
	var fade_out_px = percent_to_px(stream_layer.fade_out_range, size.x)
	var fade_in_handle  = Vector2(fade_in_px, 0)
	var fade_out_handle = Vector2(size.x - fade_out_px, 0)

	if mouse_pos.distance_to(fade_in_handle) <= handle_hit_radius:
		return "fade_in"
	elif mouse_pos.distance_to(fade_out_handle) <= handle_hit_radius:
		return "fade_out"
	return ""
