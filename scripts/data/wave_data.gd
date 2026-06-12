class_name WaveData
extends Resource

## ウェーブ定義リソース。
## シューティング・タワーディフェンスで使用。
## 詳細: docs/genres/shmup.md, docs/genres/tower-defense.md

@export var wave_number: int = 1
@export var enemy_ids: Array[String] = []
@export var spawn_count: int = 10
@export var spawn_interval: float = 1.5
@export var boss_id: String = ""  # 非空の場合、ウェーブ末尾にボスを出現させる
@export var reward_score: int = 100
