extends Camera2D

var tile_map: TileMapLayer

func set_tilemap(new_tile_map: TileMapLayer) -> void:
	tile_map = new_tile_map
	print("set tile map:", tile_map)
	_update_limits()

func _update_limits() -> void:
	if tile_map == null:
		push_warning("Camera2D: tile_map is null, cannot set limits.")
		return

	var used := tile_map.get_used_rect()            # in tile coords
	var tile_size := tile_map.tile_set.tile_size    # in pixels

	var local_pos := used.position * tile_size
	var size := used.size * tile_size

	var top_left := tile_map.to_global(local_pos)

	limit_left   = int(top_left.x)
	limit_top    = int(top_left.y)
	limit_right  = int(top_left.x + size.x)
	limit_bottom = int(top_left.y + size.y)
