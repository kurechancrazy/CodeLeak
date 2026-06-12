class_name GridUtils

## グリッド座標変換・探索ユーティリティ。
## SRPG・パズル・農業シム・タワーディフェンスで使用。
## 詳細: docs/genres/srpg.md, docs/genres/tower-defense.md


static func world_to_grid(world_pos: Vector2, tile_size: Vector2i) -> Vector2i:
	return Vector2i(int(world_pos.x / tile_size.x), int(world_pos.y / tile_size.y))


static func grid_to_world(grid_pos: Vector2i, tile_size: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * tile_size.x, grid_pos.y * tile_size.y)


static func grid_to_world_center(grid_pos: Vector2i, tile_size: Vector2i) -> Vector2:
	return grid_to_world(grid_pos, tile_size) + Vector2(tile_size) * 0.5


static func get_neighbors_4dir(pos: Vector2i) -> Array[Vector2i]:
	return [
		pos + Vector2i(0, -1),
		pos + Vector2i(1, 0),
		pos + Vector2i(0, 1),
		pos + Vector2i(-1, 0),
	]


static func get_neighbors_8dir(pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for dy: int in [-1, 0, 1]:
		for dx: int in [-1, 0, 1]:
			if dx != 0 or dy != 0:
				result.append(pos + Vector2i(dx, dy))
	return result


static func manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(b.x - a.x) + abs(b.y - a.y)


static func is_in_range(from_pos: Vector2i, to_pos: Vector2i, range_val: int) -> bool:
	return manhattan_distance(from_pos, to_pos) <= range_val


## SRPG 用: origin から range_val マス以内の移動可能セル一覧を BFS で返す。
## passable: Callable(Vector2i) -> bool — ゲーム側が通行可否を判定するコールバック。
static func get_cells_in_range(
	origin: Vector2i, range_val: int, passable: Callable
) -> Array[Vector2i]:
	var visited: Dictionary = {}
	var result: Array[Vector2i] = []
	var queue: Array[Dictionary] = [{"pos": origin, "remaining": range_val}]
	visited[origin] = true
	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		var pos: Vector2i = current.get("pos", Vector2i.ZERO)
		var remaining: int = current.get("remaining", 0)
		result.append(pos)
		if remaining <= 0:
			continue
		for neighbor: Vector2i in get_neighbors_4dir(pos):
			if visited.has(neighbor):
				continue
			if not passable.call(neighbor):
				continue
			visited[neighbor] = true
			queue.append({"pos": neighbor, "remaining": remaining - 1})
	return result
