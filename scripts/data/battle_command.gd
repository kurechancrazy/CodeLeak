class_name BattleCommand
extends RefCounted
## 戦闘コマンドデータ。BattleManager.submit_command() に渡す。
## 詳細: docs/rpg/battle-system.md

enum Type {
	ATTACK,
	MAGIC,
	ITEM,
	DEFEND,
	RUN,
}

var type: Type = Type.ATTACK
var actor_id: String = ""
var target_ids: Array[String] = []
var skill: SkillData = null
var item: ItemData = null
