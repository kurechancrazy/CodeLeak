class_name RngUtils

## 乱数ユーティリティ。
## ローグライク・シューティング・農業シムで使用。
## 詳細: docs/genres/roguelike.md, docs/genres/shmup.md


## 重み付きランダム選択。weights[i] は選ばれる確率の重み（0.0 以上）。
## 戻り値: 選ばれたインデックス。全重み 0 または空配列の場合は -1。
static func weighted_random(weights: Array[float]) -> int:
	if weights.is_empty():
		return -1
	var total: float = 0.0
	for w: float in weights:
		total += w
	if total <= 0.0:
		return -1
	var roll: float = randf() * total
	var cumulative: float = 0.0
	for i: int in weights.size():
		cumulative += weights[i]
		if roll < cumulative:
			return i
	return weights.size() - 1


## 配列からランダムに 1 要素を返す。空配列は null を返す。
static func random_element(arr: Array) -> Variant:
	if arr.is_empty():
		return null
	return arr[randi() % arr.size()]


## 配列をシャッフルしたコピーを返す（元の配列は変更しない）。
static func shuffled(arr: Array) -> Array:
	var copy: Array = arr.duplicate()
	copy.shuffle()
	return copy


## probability（0.0〜1.0）の確率で true を返す。
static func random_bool(probability: float) -> bool:
	return randf() < clampf(probability, 0.0, 1.0)
