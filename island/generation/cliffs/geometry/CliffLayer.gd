class_name CliffLayer
extends Object

var _lake_layer: LakeLayer
var _region_cell_layer: RegionCellLayer
var _height_layer: HeightLayer
var _river_layer: RiverLayer
var _road_layer: RoadLayer
var _min_slope: float
var _point_cliff_top_cell_map: Dictionary = {}  # Dictionary[int, PackedInt32Array]
var _edge_cliff_top_cell_ind_map: Dictionary = {}  # Edge key to cell index
var _cliff_base_chains: Array[PackedInt32Array] = []

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
	_get_all_the_cliff_base_chains()
#	_setup_debug_draw()
#	_split_grid_along_cliff_lines()
#	_create_cliff_polygons()

func get_cliff_base_lines() -> Array[PackedInt32Array]:
	return _cliff_base_chains

#func get_cliff_surfaces() -> Array[Array]:  # -> Array[Array[Triangle]]
#	return _cliff_surface_triangles

func _get_all_the_cliff_base_chains() -> void:
	"""
	Identify and record likely places we can extend the landscape to create cliffs
	Scan the above water cells for steep faces
	Find chains of steep faces that don't cross roads, rivers
	"""
	pass
	var cliff_edges_keys_to_array: Dictionary = {}  # Dictionary[String, PackedInt32Array]
	for cell_ind in _lake_layer.get_non_water_body_cell_indices():
		var slope_height_diff: float = _height_layer.get_slope_by_cell_index(cell_ind)
		# Only include cells that have a given minimum height difference (slope)
		if slope_height_diff < _min_slope:
			continue
		
		var point_indices_in_height_order: PackedInt32Array = (
			_height_layer.get_cell_as_point_indices_ordered_by_height(cell_ind)
		)
		# If only 1 point is low enough to touch the cliff, mark it
		if _height_layer.get_lower_edge_slope_by_cell_index(cell_ind) > (slope_height_diff * 0.5):
			_put_cliff_point_top_cell(point_indices_in_height_order[0], cell_ind)
			continue
		
		if _road_layer.cell_has_road(cell_ind):
			# Ignore cells with roads
			continue
		
		if _river_layer.cell_touches_river(cell_ind):
			# Ignore cells with rivers
			continue

		# Include the bottom edges of steep slopes
		var lower_edge_as_point_indices: PackedInt32Array = point_indices_in_height_order.slice(0,2)
		var edge_as_ordered_key: String = KeyUtils.get_combined_key_for_int32_array(lower_edge_as_point_indices)
		# remove *all* duplicate copies,
		# this prevents infinite looping when finding linked ridges later
		if edge_as_ordered_key in cliff_edges_keys_to_array:
			cliff_edges_keys_to_array.erase(edge_as_ordered_key)
		else:
			cliff_edges_keys_to_array[edge_as_ordered_key] = lower_edge_as_point_indices
			# Map the edge to the cliff TOP cell
			_edge_cliff_top_cell_ind_map[edge_as_ordered_key] = cell_ind
	
	# Find all the cliff chains
	var chains: Array[PackedInt32Array] = CliffLayer._extract_chains_from_edges(cliff_edges_keys_to_array)

	print(chains)

	for chain in chains:
		# Don't keep any chains that are too short to draw
		if len(chain) > 3:
			_cliff_base_chains.append(chain)

func _put_cliff_point_top_cell(point_ind: int, cell_ind: int) -> void:
	if point_ind in _point_cliff_top_cell_map.keys():
		_point_cliff_top_cell_map[point_ind].append(cell_ind)
	else:
		_point_cliff_top_cell_map[point_ind] = PackedInt32Array([cell_ind])

#func _get_cliff_point_top_triangles(cliff_point: Vertex) -> Array[Triangle]:
#	var key = cliff_point.get_instance_id()
#	var top_triangles: Array[Triangle] = []
#	if key in _point_cliff_top_triangles_map.keys():
#		top_triangles.append_array(_point_cliff_top_triangles_map[key])
#	return top_triangles

#func _setup_debug_draw() -> void:
#	for cliff_chain in _cliff_base_chains:
#		# Setup the debug draw
#		for i in range(len(cliff_chain)):
#			var cliff_edge: Edge = cliff_chain[i]
#			_edge_cliff_top_triangle_map[cliff_edge].set_cliff_edge(cliff_edge)
#			if i + 1 < len(cliff_chain):
#				var cliff_point: Vertex = cliff_edge.shared_point(cliff_chain[i + 1])
#				for triangle in _get_cliff_point_top_triangles(cliff_point):
#					triangle.set_cliff_point(cliff_point)

#func _split_grid_along_cliff_lines() -> void:
#	"""
#	Separate the grid where the cliffs are located
#	"""
#	# This is likely to break so much stuff. This will be interesting.
#	for cliff_chain in _cliff_base_chains:
#		_cliff_vertex_chain_pairs.append(_split_grid_along_cliff_line(cliff_chain))

#func _split_grid_along_cliff_line(cliff_chain: Array[Edge]) -> Array[Array]:  # -> Array[Array[Vertex]]
#	"""
#	Split the cliff points in the grid and separate the cliff chain by height
#
#	Return both the top chain and the bottom chain of vertices
#	"""
#	var top_vertex_chain: Array[Vertex] = []
#	var bottom_vertex_chain: Array[Vertex] = []
#	# for each non-end point in the cliff line, we need to 
#	#  - create an extra point
#	#  - create an extra edge
#	#  - separate the points vertically
#	#  - possibly link it with it's twin point in some funky way?
#
#	for i in range(len(cliff_chain) - 1):
#		# Gather info about the existing terrain elements
#		# Get a pair of edges
#		var previous_edge: Edge = cliff_chain[i]
#		var next_edge: Edge = cliff_chain[i + 1]
#
#		# Find the shared point and end points
#		var mid_point: Vertex = previous_edge.shared_point(next_edge)
#		var previous_point: Vertex = previous_edge.other_point(mid_point)
#		var next_point: Vertex = next_edge.other_point(mid_point)
#
#		# Identify the top and the base triangles around the mid point
#		var previous_cliff_top_edge_triangle: Triangle = _edge_cliff_top_triangle_map[previous_edge]
#		var previous_cliff_base_edge_triangle: Triangle = previous_edge.other_triangle(previous_cliff_top_edge_triangle)
#		var next_cliff_top_edge_triangle: Triangle = _edge_cliff_top_triangle_map[next_edge]
#		var next_cliff_base_edge_triangle: Triangle = next_edge.other_triangle(next_cliff_top_edge_triangle)
#		var cliff_top_point_triangles: Array[Triangle] = _get_cliff_point_top_triangles(mid_point)
#		var known_triangles: Array[Triangle] = cliff_top_point_triangles
#		known_triangles.append_array([
#			previous_cliff_top_edge_triangle, 
#			previous_cliff_base_edge_triangle, 
#			next_cliff_top_edge_triangle, 
#			next_cliff_base_edge_triangle
#		])
#		var cliff_base_point_triangles: Array[Triangle] = []
#		for triangle in mid_point.get_triangles():
#			if not triangle in known_triangles:
#				cliff_base_point_triangles.append(triangle)
#
#		# Create a new edge and replace the edge from the previous point 
#		# to the mid point at the bottom of this cliff
#		var new_previous_point: Vertex = previous_point
#		if not bottom_vertex_chain.is_empty():
#			new_previous_point = bottom_vertex_chain.back()
#		else:
#			bottom_vertex_chain.append(previous_point)
#			top_vertex_chain.append(previous_point)
#
#		top_vertex_chain.append(mid_point)
#		var new_cliff_base_mid_point = mid_point.duplicate_to(Vertex.new())
#		bottom_vertex_chain.append(new_cliff_base_mid_point)
#
#		var new_cliff_base_prev_edge: Edge = Edge.new(new_previous_point, new_cliff_base_mid_point)
#		previous_cliff_base_edge_triangle.replace_existing_edge_with(previous_edge, new_cliff_base_prev_edge)
#
#		# Also have to replace the point in the triangle "touching" the base of the cliff
#		for triangle in cliff_base_point_triangles:
#			triangle.replace_existing_point_with(mid_point, new_cliff_base_mid_point)
#
#		# If we're at the end of the chain, we also need to replace the edge on the next (last) edge
#		if next_edge == cliff_chain.back():
#			# next point is the last point, can just reuse
#			var new_cliff_base_next_edge: Edge = Edge.new(new_cliff_base_mid_point, next_point)
#			next_cliff_base_edge_triangle.replace_existing_edge_with(next_edge, new_cliff_base_next_edge)
#			bottom_vertex_chain.append(next_point)
#			top_vertex_chain.append(next_point)
#
#		# Raise the top of cliff point upwards
#		var additional_height: float = 5.0  # TODO: Need more rules around this
#		mid_point.raise_terrain(additional_height)
#
#	return [top_vertex_chain, bottom_vertex_chain]

#func _create_cliff_polygons() -> void:
#	"""Create the polygons that can be used to render the cliff"""
#
#	for cliff_chain_pair in _cliff_vertex_chain_pairs:
#		var cliff_polygons: Array[Triangle] = []
#		var top_chain: Array[Vertex] = cliff_chain_pair[0]
#		var bottom_chain: Array[Vertex] = cliff_chain_pair[1]
#
#		# Debug check, chains should be the same length
#		assert(len(top_chain) == len(bottom_chain), "Top and bottom chains should be the same length")
#
#		# Need to figure out the draw order.
#		# It will be reverse of the point draw direction in the existing linked triangles
#		var first_top_edge: Edge = top_chain[0].get_connection_to_point(top_chain[1])
#		if first_top_edge.get_bordering_triangles()[0].points_in_draw_order(top_chain[0], top_chain[1]):
#			# The point order needs to be the reverse of the edge in the adjoining triangle
#			top_chain.reverse()
#			bottom_chain.reverse()
#
#		for i in range(len(top_chain) - 1):
#			# Find the draw direction of the top and bottom edge in their respective triangles
#			cliff_polygons.append_array(
#				_get_cliff_polygons_for_vertices(
#					top_chain[i], top_chain[i + 1], bottom_chain[i], bottom_chain[i + 1]
#				)
#			)
#		_cliff_surface_triangles.append(cliff_polygons)

#func _get_cliff_polygons_for_vertices(top_a: Vertex, top_b: Vertex, bottom_a: Vertex, bottom_b: Vertex) -> Array[Triangle]:
#	"""Create and return the polygons required to fill this section of cliff"""
#	# When the first or last points match, we only need a single triangle
#	if top_a == bottom_a:
#		var _conn_a = Edge.new(top_b, bottom_b)
#		return [Triangle.new([top_a, top_b, bottom_b])]
#
#	if top_b == bottom_b:
#		return [Triangle.new([top_a, top_b, bottom_a])]
#
#	var _conn_a = Edge.new(top_b, bottom_b)
#	var _conn_b = Edge.new(top_b, bottom_a)
#	return [
#		Triangle.new([top_a, top_b, bottom_a]),
#		Triangle.new([top_b, bottom_b, bottom_a])
#	]

static func _extract_chains_from_edges(cliff_edges_keys_to_array: Dictionary) -> Array[PackedInt32Array]: 
	# (cliff_edges_keys_to_array: Dictionary[String, PackedInt32Array])
	"""
	Given an dictionary of unordered Edges
	Return an array, each element of which is an array of Edges ordered by connection.
	"""
	# TODO: Add to doc if: This is destructive and will leave the input dictionary empty.
	
	# Re-index the edges dictionary as a search dictionary of points to keys
	var point_indices_to_edge_keys: Dictionary = {}  # Dictionary[int, Array[String]]
	var all_edge_keys: Array = cliff_edges_keys_to_array.keys().duplicate()  # Array[String]
	for edge_key in all_edge_keys:
		var edge: PackedInt32Array = cliff_edges_keys_to_array[edge_key]
		for point_ind in edge:
			if point_ind in point_indices_to_edge_keys:
				point_indices_to_edge_keys[point_ind].append(edge_key)
			else:
				point_indices_to_edge_keys[point_ind] = [edge_key]
	
	# Identify chains by tracking each point in series of perimeter lines
	var chains: Array[PackedInt32Array] = []
	while not all_edge_keys.is_empty():
		# Setup the next chain, pick the end of a line
		var chain_done = false
		var chain_flipped = false
		var chain: PackedInt32Array = []
		var next_chain_edge_key: String = all_edge_keys.pop_back()
		var next_chain_edge: PackedInt32Array = cliff_edges_keys_to_array[next_chain_edge_key]
		var start_chain_point_ind: int = next_chain_edge[0]
		var next_chain_point_ind: int = next_chain_edge[1]
		
		# Follow the lines until we run out of edges
		chain.append(start_chain_point_ind)
		while not chain_done:
			chain.append(next_chain_point_ind)
			
			# Along which edge can we go from this point?
			# - excluding current edge and 
			# - including unvisited edges
			var connection_edge_keys: Array = point_indices_to_edge_keys[next_chain_point_ind].filter(
				func (key: String): return key != next_chain_edge_key and key in all_edge_keys
			)
			
			# If there's too many ways to go, something probably went wrong
			if len(connection_edge_keys) > 1:
				printerr("Error: Too many available directions! ")
			
			# If there's only one way to go, go that way
			elif len(connection_edge_keys) == 1:
				next_chain_edge_key = connection_edge_keys.front()
				next_chain_edge = cliff_edges_keys_to_array[next_chain_edge_key]
				next_chain_point_ind = (
					next_chain_edge[0]
					if next_chain_point_ind != next_chain_edge[0]
					else next_chain_edge[1]
				)
				all_edge_keys.erase(next_chain_edge_key)
			
			else:
				# There are no ways to go
				if chain_flipped:
					# This chain has previously been flipped, both ends are now found
					# Push this chain back into the output list
					chains.append(chain)
					chain_done = true
					continue
				
				# One end has been found, so flip it around and go the other way
				chain.reverse()
				var last_2_keys: PackedInt32Array = chain.slice(-2)
				next_chain_edge_key = KeyUtils.get_combined_key_for_int32_array(last_2_keys)
				next_chain_edge = cliff_edges_keys_to_array[next_chain_edge_key]
				next_chain_point_ind = chain[-1]
				chain.remove_at(len(chain)-1)
				chain_flipped = true
	
	return chains
