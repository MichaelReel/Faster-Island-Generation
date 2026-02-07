class_name TerrainConfig
extends Resource


@export_subgroup("Grid Creation")
@export var bounds_side: float = 50.0
@export var tri_side: float = 1.0
@export var island_cell_limit: int = 1000

@export_subgroup("Lake Creation")
@export var max_lake_regions: int = 6
@export var max_lakes_per_region: int = 3

@export_subgroup("Height Map Creation")
@export var diff_height: float = 0.2
@export var diff_max_multi: int = 3

@export_subgroup("River Creation")
@export var river_count: int = 30
@export var erode_depth: float = 0.1

@export_subgroup("Civic Creation")
@export var settlement_spread: int = 10
@export var slope_penalty: float = 5.5
@export var river_penalty: float = 10.5

@export_subgroup("Cliff Creation")
@export var min_slope_to_cliff: float = 0.5
@export var max_cliff_height: float = 1.0

@export_subgroup("Mid LOD Creation")
@export var mid_lod_noise_height: float = 1.0
@export var mid_lod_subdivision: int = 8
