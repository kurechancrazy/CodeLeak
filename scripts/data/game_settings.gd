## GameSettings — アプリ設定の型安全な定義
## Dictionary の代わりに使うことでタイプミスを実行時ではなくコンパイル時に検出できる。
## 使い方: GameManager の settings を GameSettings.new() に置き換える
##
## 移行手順（save-schema.md 参照）:
##   1. GameManager.settings: Dictionary → GameManager.settings: GameSettings
##   2. settings["key"] → settings.key に変更
##   3. SaveManager の get/set を to_dict() / from_dict() 経由に変更
class_name GameSettings
extends Resource

@export var master_volume: float = 1.0
@export var bgm_volume: float = 0.8
@export var sfx_volume: float = 1.0
@export var fullscreen: bool = false
@export var language: String = "ja"

## Dictionary に変換する（SaveManager の ConfigFile 保存に使用）。
func to_dict() -> Dictionary:
	return {
		"master_volume": master_volume,
		"bgm_volume": bgm_volume,
		"sfx_volume": sfx_volume,
		"fullscreen": fullscreen,
		"language": language,
	}

## Dictionary から GameSettings を復元する（SaveManager のロードに使用）。
static func from_dict(data: Dictionary) -> GameSettings:
	var s: GameSettings = GameSettings.new()
	s.master_volume = data.get("master_volume", 1.0)
	s.bgm_volume = data.get("bgm_volume", 0.8)
	s.sfx_volume = data.get("sfx_volume", 1.0)
	s.fullscreen = data.get("fullscreen", false)
	s.language = data.get("language", "ja")
	return s

## バリデーション: 各値が有効な範囲内か確認する。
func is_valid() -> bool:
	return (
		master_volume >= 0.0 and master_volume <= 1.0
		and bgm_volume >= 0.0 and bgm_volume <= 1.0
		and sfx_volume >= 0.0 and sfx_volume <= 1.0
		and language.length() > 0
	)
