class_name CliffLayer
extends Object

var _lake_layer: LakeLayer
var _region_cell_layer: RegionCellLayer
var _height_layer: HeightLayer
var _river_layer: RiverLayer
var _road_layer: RoadLayer
var _min_slope: float

func _init(
	lake_layer: LakeLayer,
	region_cell_layer: RegionCellLayer,
	height_layer: HeightLayer,
	river_layer: RiverLayer,
	road_layer: RoadLayer,
	min_slope: float,
) -> void:
	_lake_layer = lake_layer
	_region_cell_layer = region_cell_layer
	_height_layer = height_layer
	_river_layer = river_layer
	_road_layer = road_layer
	_min_slope = min_slope

func perform() -> void:
	pass
