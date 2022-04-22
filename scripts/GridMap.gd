extends GridMap

onready var cube_shader = preload("res://shaders/cube.gdshader")
onready var cube_texture = preload("res://textures/cube.png")
onready var bad_texture = preload("res://textures/red.png")

# Mesh sizes
var big = Vector3(4.0, 12.0, 4.0)
var mid = Vector3(4.0, 6.0, 4.0)
var lil = Vector3(4.0, 1.0, 4.0)

func set_block(x, z, type):
	if type == null:
		self.set_cell_item(x, 0, z, 0)
	self.set_cell_item(x, 0, z, type)

func set_bad_block(x, z):
	var item = self.get_cell_item(x, 0, z)
	var name = self.mesh_library.get_item_name(item)
	if name.begins_with("Large"):
		self.set_cell_item(x, 0, z, 50)
	elif name.begins_with("Medium"):
		self.set_cell_item(x, 0, z, 51)
	elif name.begins_with("Small"):
		self.set_cell_item(x, 0, z, 52)

func remove_block(x, z):
	self.set_cell_item(x, 0, z, INVALID_CELL_ITEM)

func create_mesh(meshlib: MeshLibrary, n: int, name: String, size: Vector3, colour: Color):
	# If you want a specific mesh id to look a certain way you should set it
	# to a specific mesh, but right now we're just programmatically setting
	# small/large cubes of given colours here.
	var material = ShaderMaterial.new()
	material.shader = cube_shader
	if n >= 50:
		material.set_shader_param("cube_texture", bad_texture)
	else:
		material.set_shader_param("cube_texture", cube_texture)
	material.set_shader_param("colour", colour)
	var cube = CubeMesh.new()
	cube.size = size
	cube.material = material
	var shape = BoxShape.new()
	shape.extents = size / 2.0
	meshlib.create_item(n)
	meshlib.set_item_name(n, name)
	meshlib.set_item_mesh(n, cube)
	meshlib.set_item_shapes(n, [shape, Transform.IDENTITY])

var palette = [
		Color(0.188, 0.106, 0.267, 1.0),
		Color(0.451, 0.247, 0.671, 1.0),
		Color(0.329, 0.231, 0.639, 1.0),
		Color(0.584, 0.733, 0.910, 1.0),
		Color(0.690, 0.345, 0.776, 1.0)
]

var badblock_colour = Color(1.0, 0.0, 0.0, 1.0)

func _ready():
	var ml = MeshLibrary.new()
	create_mesh(ml,  0, "SmallColour0",    lil, palette[0])
	create_mesh(ml,  1, "SmallColour1",    lil, palette[1])
	create_mesh(ml,  2, "SmallColour2",    lil, palette[2])
	create_mesh(ml,  3, "SmallColour3",    lil, palette[3])
	create_mesh(ml,  4, "SmallColour4",    lil, palette[4])
	create_mesh(ml,  5, "MediumColour0",   mid, palette[0])
	create_mesh(ml,  6, "MediumColour1",   mid, palette[1])
	create_mesh(ml,  7, "MediumColour2",   mid, palette[2])
	create_mesh(ml,  8, "MediumColour3",   mid, palette[3])
	create_mesh(ml,  9, "MediumColour4",   mid, palette[4])
	create_mesh(ml, 10, "LargeColour0",    big, palette[0])
	create_mesh(ml, 11, "LargeColour1",    big, palette[1])
	create_mesh(ml, 12, "LargeColour2",    big, palette[2])
	create_mesh(ml, 13, "LargeColour3",    big, palette[3])
	create_mesh(ml, 14, "LargeColour4",    big, palette[4])
	create_mesh(ml, 50, "LargeBad",        big, badblock_colour)
	create_mesh(ml, 51, "MediumBad",       mid, badblock_colour)
	create_mesh(ml, 52, "SmallBad",        lil, badblock_colour)
	# Add more...
	# create_mesh(ml, 10, "Thing",      lil, Color(1.0, 0.5, 0.3, 1.0))
	self.mesh_library = ml

func _on_block_loaded(type, x, y):
	set_block(x, y, type)
