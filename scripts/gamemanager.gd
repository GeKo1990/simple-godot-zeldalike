extends Node

var current_level_path: String = ""
var player_stats := {
	"max_health": 100,
	"health": 100,
}

func change_level(scene_path: String, spawn_point_name: String = "") -> void:
	current_level_path = scene_path

	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Failed to change scene to %s" % scene_path)
		return

	# Wait one frame so the new scene is fully ready
	await get_tree().process_frame

	if spawn_point_name != "":
		var root := get_tree().current_scene
		var spawn := root.get_node_or_null(spawn_point_name)
		if spawn:
			var player := get_tree().get_first_node_in_group("player")
			if player:
				player.global_position = spawn.global_position
