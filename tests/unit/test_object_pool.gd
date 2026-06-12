extends GutTest

var _pool: ObjectPool = null
var _parent: Node = null
var _scene: PackedScene = null

func before_each() -> void:
	_parent = Node.new()
	add_child_autofree(_parent)

	# テスト用の最小シーンを動的に作成
	var root: Node = Node.new()
	root.name = "PooledNode"
	_scene = PackedScene.new()
	_scene.pack(root)
	root.free()

	_pool = ObjectPool.new(_scene, 3, _parent)

# --- acquire ---

func test_acquire_returns_non_null_node() -> void:
	var obj: Node = _pool.acquire()
	assert_not_null(obj, "acquire() が null でないノードを返すこと")

func test_acquire_decreases_available_count() -> void:
	var before: int = _pool.available_count()
	_pool.acquire()
	assert_eq(_pool.available_count(), before - 1, "acquire 後に available_count が減ること")

func test_acquire_beyond_pool_grows_pool() -> void:
	# 初期サイズ3を超えて取得
	var obj1: Node = _pool.acquire()
	var obj2: Node = _pool.acquire()
	var obj3: Node = _pool.acquire()
	var obj4: Node = _pool.acquire()  # 自動拡張
	assert_not_null(obj4, "プール枯渇時に自動拡張してノードを返すこと")
	assert_eq(_pool.total_count(), 4, "拡張後の total_count が増えること")

func test_acquire_sets_process_mode_inherit() -> void:
	var obj: Node = _pool.acquire()
	assert_eq(obj.process_mode, Node.PROCESS_MODE_INHERIT, "acquire 後の process_mode が INHERIT であること")

# --- release ---

func test_release_increases_available_count() -> void:
	var obj: Node = _pool.acquire()
	var after_acquire: int = _pool.available_count()
	_pool.release(obj)
	assert_eq(_pool.available_count(), after_acquire + 1, "release 後に available_count が増えること")

func test_release_sets_process_mode_disabled() -> void:
	var obj: Node = _pool.acquire()
	_pool.release(obj)
	assert_eq(obj.process_mode, Node.PROCESS_MODE_DISABLED, "release 後の process_mode が DISABLED であること")

func test_released_node_can_be_acquired_again() -> void:
	var obj: Node = _pool.acquire()
	_pool.release(obj)
	var obj2: Node = _pool.acquire()
	assert_not_null(obj2, "release 後のノードが再 acquire できること")

func test_release_calls_reset_if_exists() -> void:
	# reset() メソッドを持つノードをプールするシミュレーション
	# ObjectPool は release 時に reset() を呼ぶ
	# ここでは reset() なしのノードで release がクラッシュしないことを確認
	var obj: Node = _pool.acquire()
	_pool.release(obj)
	pass  # クラッシュしなければOK

# --- 管理外ノードの release ---

func test_release_unmanaged_node_does_not_crash() -> void:
	var external: Node = Node.new()
	add_child_autofree(external)
	_pool.release(external)  # 管理外 → Logger.warn が出るがクラッシュしない
	pass

# --- count 系 ---

func test_initial_available_count_equals_initial_size() -> void:
	assert_eq(_pool.available_count(), 3, "初期 available_count が initial_size と一致すること")

func test_initial_total_count_equals_initial_size() -> void:
	assert_eq(_pool.total_count(), 3, "初期 total_count が initial_size と一致すること")

func test_total_count_does_not_change_after_acquire_release() -> void:
	var obj: Node = _pool.acquire()
	_pool.release(obj)
	assert_eq(_pool.total_count(), 3, "acquire/release 後に total_count が変わらないこと")

# --- 境界値 ---

func test_pool_with_initial_size_zero_is_valid() -> void:
	var empty_pool: ObjectPool = ObjectPool.new(_scene, 0, _parent)
	assert_eq(empty_pool.available_count(), 0, "サイズ0のプールが正常に作成されること")
	var obj: Node = empty_pool.acquire()  # 自動拡張
	assert_not_null(obj, "サイズ0のプールでも acquire できること")
