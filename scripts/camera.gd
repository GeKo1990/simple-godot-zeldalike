extends Camera2D

@export var tile_map_path: NodePath
@onready var tile_map: TileMapLayer = get_node(tile_map_path)

func _ready() -> void:
	_update_limits()

func _update_limits() -> void:
	if tile_map == null:
		push_warning("Camera2D has no tilemap assigned!")
		return

	var used := tile_map.get_used_rect()            # in tile coords
	var tile_size := tile_map.tile_set.tile_size    # in pixels

	var local_pos := used.position * tile_size
	var size := used.size * tile_size

	# world coordinates
	var top_left := tile_map.to_global(local_pos)

	limit_left = int(top_left.x)
	limit_top = int(top_left.y)
	limit_right = int(top_left.x + size.x)
	limit_bottom = int(top_left.y + size.y)
