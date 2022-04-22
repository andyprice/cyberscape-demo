extends Spatial

onready var map = $GridMap
onready var blockgen = $BlockGenerator
onready var viewer = $Viewer
onready var scanner = $Scanner
onready var chunk_proto = preload("res://scenes/Chunk.tscn")

const chunk_length : int = 8
const chunk_width : int = 30
const chunk_io_unit : int = 30
const chunk_size = chunk_length * chunk_width
const chunk_dist : int = 15 # Num of chunks to load before and after viewer pos
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
var block_skips = []
var block_skip_idx = 0
var row_skips = []
var row_skip_idx = 0
const ROW_SKIP_LEN = 128
const BLOCK_SKIP_LEN = 100

func _ready():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in BLOCK_SKIP_LEN:
		block_skips.append(rng.randi_range(0, chunk_width - 1))
	for i in ROW_SKIP_LEN:
		row_skips.append(rng.randi_range(0, 4))
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

var last_scanoff = 0
var rows_skipped = 0

func scan_blocks(start):
	# Are we interested in this row?
	if rows_skipped != row_skips[row_skip_idx]:
		rows_skipped += 1
		return

	row_skip_idx += 1
	if row_skip_idx == ROW_SKIP_LEN:
			row_skip_idx = 0
	rows_skipped = 0

	# Choose a block to fail the scan
	map.set_bad_block(start, block_skips[block_skip_idx])
	block_skip_idx += 1
	if block_skip_idx == BLOCK_SKIP_LEN:
		block_skip_idx = 0

const SCANNER_DIST = 30
var on_chunk = 0
func _on_viewer_moved(mover):
	var pos = mover.global_transform.origin
	scanner.global_transform.origin.x = pos.x + SCANNER_DIST
	var celloff : int = map.world_to_map(Vector3(pos.x, 0, pos.z)).x
	var scanoff : int = map.world_to_map(Vector3(pos.x + SCANNER_DIST, 0, pos.z)).x
	if scanoff != last_scanoff:
		scan_blocks(scanoff)
		last_scanoff = scanoff
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
