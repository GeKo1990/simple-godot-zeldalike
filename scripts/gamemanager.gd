extends Node

var main: Node2D = null   # assigned by Main
var current_level_path: String = ""

var player_stats := {
	"max_health": 100,
	"health": 100,
}

func change_level(scene_path: String, spawn_point_name: String = "") -> void:
	current_level_path = scene_path
	if main and main.has_method("change_level_smooth"):
		main.change_level_smooth(scene_path, spawn_point_name)
	else:
		push_error("GameManager: main is not set or has no change_level_smooth()")
