extends Node

var rng = RandomNumberGenerator.new()
func _ready():
	rng.randomize()

func load(_path):
	return true

func get_chunk(length):
	var chunk = []
	for i in length:
		var block_type = rng.randi_range(0, 14)
		chunk.append(block_type)
	return chunk

func prune():
	return
