extends GutTest


func test_world_to_grid_basic() -> void:
	var result: Vector2i = GridUtils.world_to_grid(Vector2(32.0, 64.0), Vector2i(16, 16))
	assert_eq(result, Vector2i(2, 4))


func test_world_to_grid_origin() -> void:
	assert_eq(GridUtils.world_to_grid(Vector2.ZERO, Vector2i(16, 16)), Vector2i.ZERO)


func test_grid_to_world() -> void:
	var result: Vector2 = GridUtils.grid_to_world(Vector2i(3, 2), Vector2i(16, 16))
	assert_eq(result, Vector2(48.0, 32.0))


func test_grid_to_world_center_offset() -> void:
	var result: Vector2 = GridUtils.grid_to_world_center(Vector2i(0, 0), Vector2i(16, 16))
	assert_eq(result, Vector2(8.0, 8.0))


func test_manhattan_distance_basic() -> void:
	assert_eq(GridUtils.manhattan_distance(Vector2i(0, 0), Vector2i(3, 4)), 7)


func test_manhattan_distance_zero() -> void:
	assert_eq(GridUtils.manhattan_distance(Vector2i(2, 2), Vector2i(2, 2)), 0)


func test_is_in_range_true() -> void:
	assert_true(GridUtils.is_in_range(Vector2i(0, 0), Vector2i(2, 1), 3))


func test_is_in_range_false() -> void:
	assert_false(GridUtils.is_in_range(Vector2i(0, 0), Vector2i(3, 1), 3))


func test_get_neighbors_4dir_count() -> void:
	var neighbors: Array[Vector2i] = GridUtils.get_neighbors_4dir(Vector2i(5, 5))
	assert_eq(neighbors.size(), 4)


func test_get_neighbors_8dir_count() -> void:
	var neighbors: Array[Vector2i] = GridUtils.get_neighbors_8dir(Vector2i(5, 5))
	assert_eq(neighbors.size(), 8)


func test_get_cells_in_range_includes_origin() -> void:
	var passable: Callable = func(_p: Vector2i) -> bool: return true
	var cells: Array[Vector2i] = GridUtils.get_cells_in_range(Vector2i(0, 0), 2, passable)
	assert_true(cells.has(Vector2i(0, 0)))


func test_get_cells_in_range_respects_range() -> void:
	var passable: Callable = func(_p: Vector2i) -> bool: return true
	var cells: Array[Vector2i] = GridUtils.get_cells_in_range(Vector2i(0, 0), 2, passable)
	assert_true(cells.has(Vector2i(2, 0)))
	assert_false(cells.has(Vector2i(3, 0)))


func test_get_cells_in_range_blocks_impassable() -> void:
	var block: Callable = func(p: Vector2i) -> bool: return p.x == 0 and p.y == 1
	var cells: Array[Vector2i] = GridUtils.get_cells_in_range(Vector2i(0, 0), 3, block)
	assert_false(cells.has(Vector2i(0, 2)))
