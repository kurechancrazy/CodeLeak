# Audio — AudioManager の使い方

**対象:** Godot 4.4+ / GDScript 2.0  
**実装:** `autoloads/audio_manager.gd`

---

## バスレイアウト

```
Master
├── BGM   （ループ楽曲）
└── SFX   （効果音プール × 8）
```

AudioManager が起動時に自動生成する。手動で `project.godot` に定義する必要はない。

---

## API リファレンス

### BGM の再生・停止

```gdscript
# BGM を再生（同じトラックなら再度呼んでも無視される）
AudioManager.play_bgm("main_theme")          # フェードイン 1.0秒（デフォルト）
AudioManager.play_bgm("boss_theme", 2.0)     # フェードイン 2.0秒

# BGM を停止
AudioManager.stop_bgm()                      # フェードアウト 1.0秒
AudioManager.stop_bgm(0.0)                   # 即停止

# EventBus 経由（シーンスクリプトからの推奨パターン）
EventBus.bgm_change_requested.emit("main_theme")
```

### SFX の再生

```gdscript
# SE を再生（プール内の空きプレイヤーを使用）
AudioManager.play_sfx("coin_pickup")
AudioManager.play_sfx("jump")

# EventBus 経由
EventBus.sfx_play_requested.emit("jump")
```

### 音量操作

```gdscript
# 0.0（無音）〜 1.0（最大）
AudioManager.set_master_volume(0.8)
AudioManager.set_bgm_volume(0.6)
AudioManager.set_sfx_volume(1.0)
```

音量は SaveManager と連携して保存する（後述）。

---

## ファイルパス規則

| 種類 | パス | 形式 |
|------|------|------|
| BGM | `res://assets/audio/bgm/{track_name}.ogg` | .ogg（第1候補）/ .mp3（第2候補） |
| SFX | `res://assets/audio/sfx/{sound_name}.wav` | .wav（第1候補）/ .ogg（第2候補） |

```
res://assets/audio/
├── bgm/
│   ├── main_theme.ogg
│   └── boss_theme.ogg
└── sfx/
    ├── jump.wav
    ├── coin_pickup.wav
    └── explosion.wav
```

**AudioManager はファイル名だけを引数に取る。パスと拡張子は自動解決される。**

---

## 音声ファイル形式の選択基準

| 形式 | 用途 | 理由 |
|------|------|------|
| `.ogg` | BGM（長尺ループ） | 圧縮率が高くファイルサイズ小 |
| `.wav` | SFX（短い効果音） | デコードレイテンシが低く即再生 |
| `.mp3` | BGM の代替（配布制約がある場合） | Godot 4 は MP3 をサポート |

**禁止:** SFX に `.ogg` を使うと再生開始に遅延が生じることがある → `.wav` を使う

---

## 音量設定の保存（SaveManager 連携）

```gdscript
# autoloads/game_manager.gd
func apply_audio_settings() -> void:
    AudioManager.set_bgm_volume(settings.get("bgm_volume", 0.8))
    AudioManager.set_sfx_volume(settings.get("sfx_volume", 1.0))
    AudioManager.set_master_volume(settings.get("master_volume", 1.0))

# 設定変更時: EventBus 経由で AudioManager に通知
func save_settings(key: String, value: Variant) -> void:
    settings[key] = value
    SaveManager.save()
    EventBus.settings_changed.emit(key, value)
    # AudioManager は settings_changed を購読して音量を自動更新する
```

シーンから直接 `AudioManager.set_bgm_volume()` を呼ばない。
`GameManager.settings` を更新 → `EventBus.settings_changed` → AudioManager が反応、が正しいフロー。

---

## SFX プールの上限について

プールサイズは 8（`SFX_POOL_SIZE = 8`）。
同時再生が 8 を超えると `Logger.warn("SFX pool exhausted")` が出て無視される。

**対処が必要な場合:**
- `audio_manager.gd` の `SFX_POOL_SIZE` をユーザーと相談して変更する
- 爆発・パーティクル等の多発イベントは EventBus シグナルを間引いて呼ぶ

---

## シーン遷移時の BGM 処理

```gdscript
# ✅ SceneManager の transition_started シグナルで BGM をフェードアウト
func _ready() -> void:
    SceneManager.transition_started.connect(_on_transition_started)

func _on_transition_started(_from: String, _to: String) -> void:
    AudioManager.stop_bgm(0.5)

# ✅ 新シーンの _ready で BGM を開始
func _ready() -> void:
    AudioManager.play_bgm("stage_1")
```

---

## 禁止パターン

```gdscript
# ❌ 禁止: シーンスクリプトに AudioStreamPlayer を直接置く（管理外になる）
@onready var my_player: AudioStreamPlayer = $AudioStreamPlayer

# ❌ 禁止: AudioManager を通さない play() 呼び出し
func _ready() -> void:
    $AudioStreamPlayer.play()

# ❌ 禁止: BGM ファイルを preload して渡す
AudioManager._bgm_player.stream = preload("res://assets/audio/bgm/foo.ogg")
# → 内部状態(_current_bgm)が更新されず、同じトラックを再生するとバグになる
```
