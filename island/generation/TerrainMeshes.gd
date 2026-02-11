class_name TerrainMeshes
extends Object


const GridMesh: GDScript = preload("grid/mesh/GridMesh.gd")

const IslandDebugMesh: GDScript = preload("region/mesh/IslandDebugMesh.gd")
const IslandOutlineMesh: GDScript = preload("region/mesh/IslandOutlineMesh.gd")

const LakeDebugMesh: GDScript = preload("lakes/mesh/LakeDebugMesh.gd")
const LakeOutlineMesh: GDScript = preload("lakes/mesh/LakeOutlineMesh.gd")

const HeightMesh: GDScript = preload("height/mesh/HeightMesh.gd")

const WaterMesh: GDScript = preload("rivers/mesh/WaterMesh.gd")
const DebugRiverMesh: GDScript = preload("rivers/mesh/DebugRiverMesh.gd")

const SettlementsMesh: GDScript = preload("civil/mesh/SettlementsMesh.gd")
const RoadsMesh: GDScript = preload("civil/mesh/RoadsMesh.gd")

const CliffLineMesh: GDScript = preload("cliffs/mesh/CliffLineMesh.gd")
const CliffTerrainMesh: GDScript = preload("cliffs/mesh/CliffTerrainMesh.gd")

const MidLODBaseMesh: GDScript = preload("mid_lod/mesh/MidLODBaseMesh.gd")


var grid_mesh: GridMesh

var island_debug_mesh: IslandDebugMesh
var island_outline_mesh: IslandOutlineMesh

var lake_debug_mesh: LakeDebugMesh
var lake_outline_mesh: LakeOutlineMesh

var height_mesh: HeightMesh

var water_mesh: WaterMesh
var debug_river_mesh: DebugRiverMesh
var eroded_height_mesh: HeightMesh

var settlements_mesh: SettlementsMesh
var roads_mesh: RoadsMesh

var cliff_line_mesh: CliffLineMesh
var cliff_terrain_mesh: CliffTerrainMesh

var mid_lod_base_mesh: MidLODBaseMesh
