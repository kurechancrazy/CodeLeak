## ObjectPool — ノードの再利用プール
## 毎秒10個以上を生成・破棄する場合にインスタンス化コストを削減する。
## 使い方: var pool = ObjectPool.new(SCENE, 10, self)
##          var obj = pool.acquire()  /  pool.release(obj)
class_name ObjectPool
extends RefCounted

var _scene: PackedScene
var _parent: Node
var _all: Array[Node] = []
var _inactive: Array[Node] = []

## scene: プールするシーン / initial_size: 初期確保数 / parent: add_child 先
func _init(scene: PackedScene, initial_size: int, parent: Node) -> void:
	_scene = scene
	_parent = parent
	for i: int in range(initial_size):
		_inactive.append(_create_instance())

## プールからノードを取得する。プールが空の場合は自動拡張（警告ログ付き）。
func acquire() -> Node:
	if _inactive.is_empty():
		Logger.warn("ObjectPool exhausted, growing", {
			"scene": _scene.resource_path,
			"total": _all.size()
		})
		return _create_instance()
	var obj: Node = _inactive.pop_back()
	obj.process_mode = Node.PROCESS_MODE_INHERIT
	return obj

## ノードをプールに返却する。reset() メソッドがあれば自動呼び出し。
func release(obj: Node) -> void:
	if not obj in _all:
		Logger.warn("ObjectPool: 管理外のノードを release しようとしました", {})
		return
	if obj.has_method("reset"):
		obj.reset()
	obj.process_mode = Node.PROCESS_MODE_DISABLED
	_inactive.append(obj)

## 現在プールに待機中のノード数を返す。
func available_count() -> int:
	return _inactive.size()

## プールが管理するノードの合計数を返す。
func total_count() -> int:
	return _all.size()

func _create_instance() -> Node:
	var obj: Node = _scene.instantiate()
	obj.process_mode = Node.PROCESS_MODE_DISABLED
	_parent.add_child(obj)
	_all.append(obj)
	return obj
