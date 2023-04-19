class_name Outputlayer
extends Stage

var readied: bool = false

var _tri_cell_layer: TriCellLayer
var _height_layer: HeightLayer
var _cliff_layer: CliffLayer

func _init(
	tri_cell_layer: TriCellLayer,
	height_layer: HeightLayer,
	cliff_layer: CliffLayer,
) -> void:
	_tri_cell_layer = tri_cell_layer
	_height_layer = height_layer
	_cliff_layer = cliff_layer

func perform() -> void:
	readied = true


func get_height_at_xz(xz: Vector2) -> float:
	if not readied:
		return 0.0
	
	# Find the cell this point is in (or not)
	# Find the position within the cell
	# Calculate the height at this position
	
	return 10.0
