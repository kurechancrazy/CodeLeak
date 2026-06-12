extends GutTest

var _pm: Node = null


func before_each() -> void:
	_pm = load("res://autoloads/party_manager.gd").new()
	# _ready() を呼ばず EventBus 依存を回避して純粋ロジックのみテスト


func after_each() -> void:
	_pm.free()


func _make_member(id: String, hp: int = 100) -> CharacterData:
	var member: CharacterData = CharacterData.new()
	member.id = id
	member.max_hp = hp
	member.current_hp = hp
	return member


# --- add_member ---

func test_add_member_returns_true() -> void:
	var member: CharacterData = _make_member("hero")
	assert_true(_pm.add_member(member))


func test_add_member_increases_party_size() -> void:
	_pm.add_member(_make_member("hero"))
	assert_eq(_pm.party_members.size(), 1)


func test_add_member_fails_when_full() -> void:
	_pm._max_party_size = 2
	_pm.add_member(_make_member("hero"))
	_pm.add_member(_make_member("mage"))
	var result: bool = _pm.add_member(_make_member("thief"))
	assert_false(result, "パーティーが満員のとき false を返すこと")


# --- remove_member ---

func test_remove_member_decreases_party_size() -> void:
	_pm.add_member(_make_member("hero"))
	_pm.remove_member("hero")
	assert_eq(_pm.party_members.size(), 0)


func test_remove_nonexistent_member_does_not_crash() -> void:
	_pm.remove_member("ghost")
	assert_eq(_pm.party_members.size(), 0)


# --- get_member ---

func test_get_member_returns_correct_member() -> void:
	var member: CharacterData = _make_member("hero")
	_pm.add_member(member)
	var result: CharacterData = _pm.get_member("hero")
	assert_eq(result.id, "hero")


func test_get_member_returns_null_for_unknown_id() -> void:
	assert_null(_pm.get_member("unknown"))


# --- alive_members ---

func test_alive_members_excludes_ko() -> void:
	var alive: CharacterData = _make_member("hero", 100)
	var dead: CharacterData = _make_member("mage", 100)
	dead.current_hp = 0
	_pm.add_member(alive)
	_pm.add_member(dead)
	assert_eq(_pm.alive_members().size(), 1)


# --- is_all_defeated ---

func test_is_all_defeated_true_when_empty() -> void:
	assert_true(_pm.is_all_defeated())


func test_is_all_defeated_false_when_alive_member() -> void:
	_pm.add_member(_make_member("hero"))
	assert_false(_pm.is_all_defeated())


func test_is_all_defeated_true_when_all_ko() -> void:
	var member: CharacterData = _make_member("hero", 100)
	member.current_hp = 0
	_pm.add_member(member)
	assert_true(_pm.is_all_defeated())


# --- restore_all_hp ---

func test_restore_all_hp_restores_full_hp() -> void:
	var member: CharacterData = _make_member("hero", 100)
	member.current_hp = 10
	_pm.add_member(member)
	_pm.restore_all_hp()
	assert_eq(_pm.party_members[0].current_hp, 100)
