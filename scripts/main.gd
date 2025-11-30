extends Node2D

@onready var level_root: Node2D = $LevelRoot

@onready var player: CharacterBody2D = $player
@onready var camera: Camera2D = $player/Camera2D

func _ready() -> void:
	GameManager.main = self
	GameManager.change_level("res://scenes/levels/Start.tscn", "Spawn")

func load_level(scene_path: String, spawn_point_name: String = "") -> void:
	for child in level_root.get_children():
		child.queue_free()

	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Main: Could not load level scene: %s" % scene_path)
		return

	var level := packed.instantiate()
	level_root.add_child(level)

	var tile_map: TileMapLayer = null
	for n in level.get_children():
		if n.is_in_group("level_tilemap"):
			tile_map = n
			break

	if tile_map and camera:
		camera.set_tilemap(tile_map)

	if spawn_point_name != "":
		var spawn := level.get_node_or_null(spawn_point_name)
		if spawn:
			player.global_position = spawn.global_position
