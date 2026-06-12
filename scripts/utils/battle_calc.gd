class_name BattleCalc
## ターンベース RPG の戦闘計算式。全関数 static で副作用なし。
## 詳細: docs/rpg/battle-system.md

## 物理ダメージ。最低 1 を保証する。
static func physical_damage(
	attacker: CharacterData,
	target: CharacterData,
	variance: float = 0.1
) -> int:
	var base: float = float(attacker.strength) * 2.0 - float(target.defense)
	base = maxf(base, 1.0)
	return int(base * (1.0 + randf_range(-variance, variance)))


## 魔法ダメージ。属性一致で 1.5 倍。最低 1 を保証する。
static func magic_damage(
	attacker: CharacterData,
	target: CharacterData,
	skill: SkillData
) -> int:
	var base: float = float(skill.power) + float(attacker.magic) - float(target.magic_defense)
	base = maxf(base, 1.0)
	return int(base * skill.element_multiplier(target.element_weakness))


## クリティカル判定。luck が高いほど発生率が上がる。
static func is_critical(attacker: CharacterData) -> bool:
	return randf() < float(attacker.luck) / 100.0


## ステータス異常命中判定。攻撃側 luck と防御側 luck の差で補正。
static func status_hit(
	attacker: CharacterData,
	target: CharacterData,
	base_rate: float
) -> bool:
	var adjusted: float = base_rate * (1.0 + float(attacker.luck - target.luck) / 100.0)
	return randf() < clampf(adjusted, 0.0, 1.0)
