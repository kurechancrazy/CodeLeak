# Design — Bilingual Support (EN/JA) & How to Play

## Architecture Pattern & Boundary Map

```
┌──────────────────────────────────────────────────────────────┐
│  assets/i18n/translations.csv  (new)                         │
│  keys | en | ja                                              │
└───────────────────┬──────────────────────────────────────────┘
                    │ registered in project.godot [internationalization]
                    ▼
         TranslationServer (Godot built-in)
                    │  tr("KEY")
         ┌──────────┴─────────────────────────────┐
         │                                        │
┌────────▼──────────┐              ┌──────────────▼──────────┐
│  SaveManager      │              │  GameManager             │
│  _load_settings() │─ restore ───▶│  settings["language"]    │
│  save_settings()  │◀─ persist ───│  update_setting(...)     │
└───────────────────┘              │  _on_settings_changed()  │
                                   │   └─ set_locale()        │
                                   └──────────┬───────────────┘
                                              │ EventBus.settings_changed
                              ┌───────────────┼───────────────┐
                              ▼               ▼               ▼
                        main_menu.gd    game_hud.gd    pause_menu.gd
                        (+ HTP overlay) _refresh_labels() _refresh_labels()
                              ▼
                     investigation_panel.gd  result_screen.gd
                        (feedback strings)   _refresh_labels()
                              ▼
                         game_screen.gd
                          (SYSTEM SECURED)
```

**Dependency rule:** No Autoload touches another Autoload directly. Language change flows through `GameManager.update_setting()` → `EventBus.settings_changed` → UI scenes update independently.

---

## Technology Stack & Alignment

| Concern | Solution | Rationale |
|---------|----------|-----------|
| Translation storage | `assets/i18n/translations.csv` (key, en, ja) | Godot 4 built-in; no plugin needed |
| Runtime locale | `TranslationServer.set_locale(locale)` | Engine API; `tr()` auto-routes |
| Locale persistence | `SaveManager.save_settings()` via `GameManager.settings["language"]` | Already exists; zero new schema |
| Change propagation | `EventBus.settings_changed("language", locale)` | Already exists; scenes connect |
| Default locale | `"en"` (change from `"ja"` in `game_manager.gd`) | Req 1.2 — English is primary |
| How to Play | Overlay `Panel` in `main_menu.gd` | Avoids new scene; consistent with dynamic-build pattern |

---

## Components & Interface Contracts

### 1. `assets/i18n/translations.csv` (new file)

CSV with columns `key,en,ja`. All keys are UPPER_SNAKE_CASE.

**Required keys:**

| Key | English | Japanese |
|-----|---------|----------|
| `MAIN_SUBTITLE` | `[ debug the machine before it debugs you ]` | `[ AIの嘘を見抜け ]` |
| `BTN_PLAY` | `[ PLAY ]` | `[ プレイ ]` |
| `BTN_HOW_TO_PLAY` | `[ HOW TO PLAY ]` | `[ 遊び方 ]` |
| `BTN_QUIT` | `[ QUIT ]` | `[ 終了 ]` |
| `LANG_TOGGLE_TO_JA` | `[JA]` | `[EN]` |
| `HUD_SCORE_PREFIX` | `SCORE:` | `スコア:` |
| `HUD_HINTS_PREFIX` | `HINTS:` | `ヒント:` |
| `HUD_LEVEL_PREFIX` | `LEVEL` | `レベル` |
| `BTN_HINT` | `[HINT]` | `[ヒント]` |
| `FEEDBACK_PATCHED` | `>> PATCHED` | `>> パッチ適用` |
| `FEEDBACK_DENIED` | `>> ACCESS DENIED` | `>> アクセス拒否` |
| `PAUSE_TITLE` | `// PAUSED` | `// 一時停止` |
| `BTN_RESUME` | `[RESUME]` | `[再開]` |
| `BTN_RESTART_LEVEL` | `[RESTART LEVEL]` | `[レベル再起動]` |
| `BTN_MAIN_MENU` | `[MAIN MENU]` | `[メインメニュー]` |
| `RESULT_TITLE` | `// ANALYSIS COMPLETE` | `// 解析完了` |
| `RESULT_SCORE_PREFIX` | `SCORE:` | `スコア:` |
| `RESULT_TIME_PREFIX` | `TIME:` | `タイム:` |
| `RESULT_MISS_PREFIX` | `MISS:` | `ミス:` |
| `RESULT_HINTS_PREFIX` | `HINTS USED:` | `使用ヒント:` |
| `RESULT_NEW_HIGH` | `>> NEW HIGH SCORE!` | `>> ハイスコア更新!` |
| `BTN_RETRY` | `[RETRY]` | `[リトライ]` |
| `SYSTEM_SECURED` | `[SYSTEM SECURED]` | `[システム確保]` |
| `HTP_TITLE` | `// HOW TO PLAY` | `// 遊び方` |
| `HTP_MISSION_TITLE` | `MISSION` | `ミッション` |
| `HTP_MISSION` | `Analyze AI-generated code. Find the hidden malicious logic and patch it before it executes.` | `AIが生成したコードを解析せよ。隠された悪意ある処理を見つけ、実行前に修正しろ。` |
| `HTP_CODE_TITLE` | `CODE PANEL (LEFT)` | `コードパネル（左）` |
| `HTP_CODE` | `Read the code. Click a suspicious line to open the investigation panel.` | `コードを読み、怪しい行をクリックして調査パネルを開け。` |
| `HTP_INVEST_TITLE` | `INVESTIGATION PANEL (RIGHT)` | `調査パネル（右）` |
| `HTP_INVEST` | `Answer the question about the selected line. Press [A][B][C][D] or click.` | `選択行に関する質問に答えよ。[A][B][C][D]を押すかクリック。` |
| `HTP_HINT_TITLE` | `HINTS` | `ヒント` |
| `HTP_HINT` | `Press [HINT] to highlight a suspicious line. Limited uses per level.` | `[ヒント]で怪しい行をハイライト。レベルごとに使用回数制限あり。` |
| `HTP_SCORE_TITLE` | `SCORING` | `スコア` |
| `HTP_SCORE` | `Fast clear = time bonus. Wrong answers = score penalty.` | `素早いクリアでタイムボーナス。誤答はスコアペナルティ。` |
| `BTN_CLOSE` | `[CLOSE]` | `[閉じる]` |

---

### 2. `project.godot` (modified)

Add localization registration under `[internationalization]` section:

```ini
[internationalization]

locale/translations=PackedStringArray("res://assets/i18n/translations.csv")
locale/locale_filter_mode=1
locale/language_filter=PackedStringArray("en", "ja")
```

---

### 3. `autoloads/game_manager.gd` (modified)

**Change:** Default language from `"ja"` to `"en"`.

**Change:** In `_on_settings_changed()`, when `key == "language"`, call `TranslationServer.set_locale(value as String)`.

**Interface contract:**
```
update_setting("language", "en")  →  settings["language"] = "en"
                                   →  EventBus.settings_changed.emit("language", "en")
                                   →  TranslationServer.set_locale("en")
                                   →  SaveManager.save_settings() [called by scene]
```

---

### 4. `autoloads/save_manager.gd` (modified)

**Change:** At end of `_load_settings()`, apply restored locale:
```
TranslationServer.set_locale(GameManager.settings["language"])
```
This runs after SaveManager initializes (Autoload order 6), ensuring the restored locale is active before any scene renders.

---

### 5. `scenes/ui/main_menu.gd` (modified)

**New elements in `_build_layout()`:**
- Language toggle button (`_lang_btn: Button`) — positioned top-right via `Control.PRESET_TOP_RIGHT`
- `[HOW TO PLAY]` button in the main VBox between `[PLAY]` and `[QUIT]`
- How to Play overlay Panel (`_htp_overlay: Panel`) — full-rect, hidden by default

**New fields:**
```gdscript
var _subtitle_label: Label
var _play_btn: Button
var _htp_btn: Button
var _quit_btn: Button
var _lang_btn: Button
var _htp_overlay: Panel
```

**New methods:**
- `_refresh_labels() -> void` — re-applies `tr()` to all stored label/button references
- `_on_lang_pressed() -> void` — toggles `GameManager.settings["language"]` between `"en"` and `"ja"`, calls `GameManager.update_setting()`
- `_build_htp_overlay() -> void` — builds the How to Play panel (hidden Panel with title + sections + close button)
- `_show_htp(show: bool) -> void` — sets `_htp_overlay.visible`

**Signal connections:**
```gdscript
EventBus.settings_changed.connect(_on_settings_changed)

func _on_settings_changed(key: String, _value: Variant) -> void:
    if key == "language":
        _refresh_labels()
```

**`_input()` override:** When `_htp_overlay.visible` and `cancel` pressed → `_show_htp(false)`.

---

### 6. `scenes/ui/game_hud.gd` (modified)

**Change:** Convert dynamic labels to use translated prefix.

Pattern for score:
```
_score_label.text = "%s %d" % [tr("HUD_SCORE_PREFIX"), score]
```

**New method:** `_refresh_labels() -> void` — rebuilds static text using `tr()`.

**Signal:** Connect `EventBus.settings_changed` → `_refresh_labels()` when key == `"language"`.

---

### 7. `scenes/game/investigation_panel.gd` (modified)

**Change:** Replace hardcoded feedback strings with `tr()` calls at the point of assignment.

```gdscript
_feedback_label.text = "%s\n   %s" % [tr("FEEDBACK_PATCHED"), explanation]
_feedback_label.text = tr("FEEDBACK_DENIED")
_hint_button.text = tr("BTN_HINT")
```

No `_refresh_labels()` needed for feedback (feedback is set reactively when events fire, which already calls `tr()` at that moment).
`_hint_button.text` needs refresh → connect to `settings_changed`.

---

### 8. `scenes/ui/pause_menu.gd` (modified)

**Change:** Store button/label references; add `_refresh_labels()`.

**Signal:** Connect `EventBus.settings_changed` → `_refresh_labels()` when key == `"language"`.

---

### 9. `scenes/ui/result_screen.gd` (modified)

**Change:** Replace hardcoded prefixes with `tr()`. Dynamic values use split-prefix pattern:
```
_score_label.text = "%s %d" % [tr("RESULT_SCORE_PREFIX"), _result_score]
_time_label.text = "%s  %s" % [tr("RESULT_TIME_PREFIX"), _format_time(_result_time)]
```

**New method:** `_refresh_labels() -> void`.

**Signal:** Connect `EventBus.settings_changed` → `_refresh_labels()`.

---

### 10. `scenes/game/game_screen.gd` (modified)

**Change:** In `_play_secured_sequence()`, replace `"[SYSTEM SECURED]"` with `tr("SYSTEM_SECURED")`.

No `_refresh_labels()` needed (the text is set once when the animation starts and is not visible during language changes).

---

## Requirements Traceability

| Requirement | Component |
|-------------|-----------|
| 1.1 Translation file | `assets/i18n/translations.csv`, `project.godot` |
| 1.2 Default language EN | `game_manager.gd` settings default |
| 2.1 Main Menu | `main_menu.gd` `_refresh_labels()` |
| 2.2 HUD | `game_hud.gd` `_refresh_labels()` |
| 2.3 Investigation Panel | `investigation_panel.gd` `tr()` at assignment |
| 2.4 Pause Menu | `pause_menu.gd` `_refresh_labels()` |
| 2.5 Result Screen | `result_screen.gd` `_refresh_labels()` |
| 2.6 SYSTEM SECURED | `game_screen.gd` `tr("SYSTEM_SECURED")` |
| 3.1 Language toggle | `main_menu.gd` `_lang_btn` |
| 3.2 Language persistence | `save_manager.gd` `save_settings()` / `_load_settings()` |
| 4.1 HTP entry point | `main_menu.gd` `_htp_btn` |
| 4.2 HTP content | `main_menu.gd` `_build_htp_overlay()` |
| 4.3 HTP dismissal | `main_menu.gd` `_show_htp(false)` + `_input()` |
| 5.1 Dynamic label refresh | All scenes: `EventBus.settings_changed` → `_refresh_labels()` |
