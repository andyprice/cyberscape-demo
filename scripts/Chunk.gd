extends Node

signal chunk_invalid(chunk)

var on_chunk = 0

func _on_viewer_moved(player, chunk, w, map, valid_dist):
	var pos = player.global_transform.origin
	var celloff : int = map.world_to_map(Vector3(pos.x, 0, pos.y)).x
	# warning-ignore:integer_division
	var curr_chunk : int = celloff / w
	if curr_chunk < 0:
		curr_chunk = 0
	if on_chunk == curr_chunk:
		return
	on_chunk = curr_chunk
	if chunk < curr_chunk - valid_dist or chunk >= curr_chunk + valid_dist:
		emit_signal("chunk_invalid", chunk)
		queue_free()
