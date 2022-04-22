extends Spatial

onready var map = $GridMap
onready var blockgen = $BlockGenerator
onready var viewer = $Viewer
onready var scanner = $Scanner
onready var chunk_proto = preload("res://scenes/Chunk.tscn")

const chunk_length : int = 8
const chunk_width : int = 50
const chunk_io_unit : int = 50
const chunk_size = chunk_length * chunk_width
const chunk_dist : int = 25 # Num of chunks to load before and after viewer pos
const io_usecs_limit = 2000 # microseconds

var go = false

func block_to_world(block: int):
	# warning-ignore:integer_division
	var x = block / chunk_width
	var y = block % chunk_width
	return map.map_to_world(x, 0, y)

func world_to_block(coords):
	var cell = map.world_to_map(coords)
	return cell.x * chunk_width + cell.z

func unload_chunk(i):
	var chunk_xoffset = i * chunk_length
	for x in chunk_length:
		for z in chunk_width:
			map.remove_block(chunk_xoffset + x, z)

var chunk_reader

func _ready():
	# Start coroutine
	chunk_reader = read_chunks()
	yield(get_tree().create_timer(0.1), "timeout")
	for i in chunk_dist:
		read_chunk(i)
	go = true

func read_chunk(n):
	chunk_reader = chunk_reader.resume(n)

signal block_loaded(block, x, y)

# This function is big and ugly but it has to yield at various points
# so it's difficult to split.
# TODO: Remove the debugging/timing clutter
func read_chunks():
	var queue = []
	while true:
		var chunk = queue.pop_front()
		while chunk == null:
			# No chunks requested, wait until they are
			chunk = yield()

		# Read a chunk
		var stamp = OS.get_ticks_usec()
		var start = chunk_size * chunk
		for i in range(0, chunk_size, chunk_io_unit):
			# Read a block
			var blocks = blockgen.get_chunk(chunk_io_unit)
			if blocks == null || blocks.size() == 0:
				continue
			var bend = OS.get_ticks_usec()
			for j in chunk_io_unit:
				var block = blocks[j]
				var x = (start + i + j) / chunk_width
				var y = (start + i + j) % chunk_width
				emit_signal("block_loaded", block, x, y)
				var dur = bend - stamp
				# Yield if we're out of time
				if dur > io_usecs_limit:
					var n = yield()
					stamp = OS.get_ticks_usec()
					if n != null && n != chunk:
						queue.append(n)
		var chunkobj = chunk_proto.instance()
		var _err = viewer.connect("viewer_moved", chunkobj, "_on_viewer_moved", [chunk, chunk_length, map, chunk_dist], CONNECT_DEFERRED)
		_err = chunkobj.connect("chunk_invalid", self, "_on_chunk_invalid", [], CONNECT_DEFERRED)

func _on_chunk_invalid(chunk):
	unload_chunk(chunk)
	blockgen.prune()

func _process(_delta):
	chunk_reader = chunk_reader.resume()

var on_chunk = 0
func _on_viewer_moved(mover):
	var pos = mover.global_transform.origin
	scanner.global_transform.origin.x = pos.x + 40
	var celloff : int = map.world_to_map(Vector3(pos.x, 0, pos.z)).x
	# warning-ignore:integer_division
	var curr_chunk : int = celloff / chunk_length
	if curr_chunk < 0:
		curr_chunk = 0
	if on_chunk == curr_chunk:
		return
	on_chunk = curr_chunk
	var min_chunk = curr_chunk - chunk_dist + 1
	if min_chunk < 0:
		min_chunk = 0
	var max_chunk = curr_chunk + chunk_dist - 1
	if map.get_cell_item(max_chunk * chunk_length, 0, 0) == map.INVALID_CELL_ITEM:
		read_chunk(max_chunk)
	if map.get_cell_item(min_chunk * chunk_length, 0, 0) == map.INVALID_CELL_ITEM:
		read_chunk(min_chunk)
