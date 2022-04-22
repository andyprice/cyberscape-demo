extends Node

var cache_size = 512 # Chunks
var cache = []
var cache_idx = 0;

var rng = RandomNumberGenerator.new()
func _ready():
	rng.randomize()

func load(_path):
	return true

func get_chunk(length):
	var chunk = []
	if cache.size() < cache_size:
		for i in length:
			var block_type = rng.randi_range(0, 14)
			chunk.append(block_type)
		cache.append(chunk)
	else:
		chunk = cache[cache_idx]
		cache_idx += 1
		if cache_idx >= cache_size:
			cache_idx = 0
	return chunk

func prune():
	return
