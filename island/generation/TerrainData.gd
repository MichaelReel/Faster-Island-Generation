class_name TerrainData
extends Object


const GridPointLayer: GDScript = preload("grid/geometry/PointLayer.gd")
const GridTriCellLayer: GDScript = preload("grid/geometry/TriCellLayer.gd")

const IslandOutlineLayer: GDScript = preload("region/geometry/IslandOutlineLayer.gd")
const RegionCellLayer: GDScript = preload("region/geometry/RegionCellLayer.gd")

const RegionDivideLayer: GDScript = preload("lakes/geometry/RegionDivideLayer.gd")
const LakeLayer: GDScript = preload("lakes/geometry/LakeLayer.gd")

const HeightLayer: GDScript = preload("height/geometry/HeightLayer.gd")

const RiverLayer: GDScript = preload("rivers/geometry/RiverLayer.gd")

const SettlementLayer: GDScript = preload("civil/geometry/SettlementLayer.gd")
const RoadLayer: GDScript = preload("civil/geometry/RoadLayer.gd")

const CliffLayer: GDScript = preload("cliffs/geometry/CliffLayer.gd")

const LowLODAggregateLayer: GDScript = preload("mid_lod/geometry/LowLODAggregateLayer.gd")
const MidLODPointLayer: GDScript = preload("mid_lod/geometry/MidLODPointLayer.gd")
const MidLODTriCellLayer: GDScript = preload("mid_lod/geometry/MidLODTriCellLayer.gd")


var grid_point_layer: GridPointLayer
var grid_tri_cell_layer: GridTriCellLayer

var region_cell_layer: RegionCellLayer
var island_outline_layer: IslandOutlineLayer

var region_divide_layer: RegionDivideLayer
var lake_layer: LakeLayer

var height_layer: HeightLayer

var river_layer: RiverLayer

var settlement_layer: SettlementLayer
var road_layer: RoadLayer

var cliff_layer: CliffLayer

var low_lod_agg_layer: LowLODAggregateLayer
var mid_lod_point_layer: MidLODPointLayer
var mid_lod_tri_cell_layer: MidLODTriCellLayer


func get_height_at_xz(xz: Vector2) -> float:
	if low_lod_agg_layer:
		return low_lod_agg_layer.get_height_at_xz(xz)
	else:
		return 0.0
