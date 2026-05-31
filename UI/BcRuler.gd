@tool
class_name BcRuler
extends Control

enum RulerOrientation { HORIZONTAL, VERTICAL }

@export var orientation: RulerOrientation = RulerOrientation.HORIZONTAL

const INTERVAL = 100
const FONT_SIZE = 9
var rtpc: RTPC

func _draw() -> void:
	match orientation:
		RulerOrientation.HORIZONTAL:
			_draw_horizontal()
		RulerOrientation.VERTICAL:
			_draw_vertical()

func _draw_horizontal() -> void:
	var width = size.x
	var height = size.y
	
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.15, 0.15, 0.15))
	
	var range_min = rtpc.min_value if rtpc else 0.0
	var range_max = rtpc.max_value if rtpc else 100.0
	var range_total = range_max - range_min
	var steps = int(width / INTERVAL) + 1
	
	for i in range(steps):
		var x = i * INTERVAL
		var t = x / width  # 0.0 à 1.0 selon la position
		var value = range_min + t * range_total
		draw_line(Vector2(x, 0), Vector2(x, 6), Color.WHITE, 1.0)
		draw_string(
			ThemeDB.fallback_font,
			Vector2(x + 3, 14),
			str(snapped(value, 1.0)),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			FONT_SIZE,
			Color(0.8, 0.8, 0.8)
		)

func _draw_vertical() -> void:
	pass # à implémenter quand nécessaire

func _notification(what) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
