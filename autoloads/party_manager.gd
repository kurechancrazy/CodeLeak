extends Node
## パーティーメンバーのステータス・編成を管理する Autoload。
## 戦闘・フィールド・メニュー全シーンから参照される。

# パーティーメンバー（最大 4 名）
var party_members: Array[CharacterData] = []

# 現在操作中のメンバー（メニューのカーソル位置等）
var active_member_id: String = ""

var _max_party_size: int = 4

func _ready() -> void:
	EventBus.load_requested.connect(_on_load)
	EventBus.save_requested.connect(_on_save)

func _exit_tree() -> void:
	EventBus.load_requested.disconnect(_on_load)
	EventBus.save_requested.disconnect(_on_save)

# ── 公開 API ──────────────────────────────────────────────

func add_member(member: CharacterData) -> bool:
	if party_members.size() >= _max_party_size:
		Logger.warn("Party is full", {"id": member.id})
		return false
	party_members.append(member)
	EventBus.party_status_changed.emit()
	return true

func remove_member(member_id: String) -> void:
	party_members = party_members.filter(
		func(m: CharacterData) -> bool: return m.id != member_id
	)
	EventBus.party_status_changed.emit()

func get_member(member_id: String) -> CharacterData:
	for member: CharacterData in party_members:
		if member.id == member_id:
			return member
	return null

func alive_members() -> Array[CharacterData]:
	return party_members.filter(
		func(m: CharacterData) -> bool: return m.is_alive()
	)

func is_all_defeated() -> bool:
	return alive_members().is_empty()

func restore_all_hp() -> void:
	for member: CharacterData in party_members:
		member.current_hp = member.max_hp
		member.current_mp = member.max_mp
	EventBus.party_status_changed.emit()

# ── セーブ・ロード ────────────────────────────────────────

func _on_save() -> void:
	var data: Array = party_members.map(
		func(m: CharacterData) -> Dictionary: return m.to_dict()
	)
	SaveManager.set_value("party", "members", JSON.stringify(data))

func _on_load() -> void:
	var raw: Variant = SaveManager.get_value("party", "members", "[]")
	if not raw is String:
		return
	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Array:
		return
	# ロード処理: CharacterData は .tres から事前ロードして from_dict で上書き
	for i: int in range(mini(parsed.size(), party_members.size())):
		party_members[i].from_dict(parsed[i])
	EventBus.party_status_changed.emit()
