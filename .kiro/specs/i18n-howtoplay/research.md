# Research — i18n-howtoplay

## Summary

Discovery type: **Extension** (integrating Godot's built-in translation system into an existing codebase).
All infrastructure for language persistence already exists (`GameManager.settings["language"]`, `EventBus.settings_changed`, `SaveManager._load_settings()`). The main work is:
1. Creating the CSV and wiring `TranslationServer`
2. Replacing hardcoded strings with `tr()` calls and split-prefix patterns for dynamic labels
3. Adding language toggle + How to Play overlay to `main_menu.gd`

---

## Research Log

### Topic 1: Godot 4 Localization System

**Findings:**
- Godot 4 supports `.csv` translation files with `key,locale` columns
- `TranslationServer.set_locale("en")` changes the active locale at runtime
- `tr("KEY")` returns the current-locale string; falls back to the key itself if missing
- CSV must be registered under Project Settings → Localization → Translations
- In Godot 4, `project.godot` stores: `[internationalization] / locale/translations = PackedStringArray("res://assets/i18n/translations.csv")`
- `.csv` is imported as a Translation resource automatically by the editor

**Implication:** No new plugin needed. Pure engine feature.

### Topic 2: Existing Language Infrastructure

**Findings (from codebase analysis):**
- `GameManager.settings["language"]` already exists, default `"ja"` → **must change to `"en"`**
- `GameManager.update_setting("language", val)` already emits `EventBus.settings_changed("language", val)`
- `SaveManager._load_settings()` already restores all settings including `"language"` on boot
- `SaveManager.save_settings()` persists all settings → language preference automatically persisted once `update_setting` is called
- `EventBus.settings_changed` signal already defined

**Gap:** `TranslationServer.set_locale()` is never called anywhere. Must be added to `GameManager._ready()` (after settings load) and in `_on_settings_changed` when key == `"language"`.

**Gap:** `SaveManager._load_settings()` runs before `GameManager._ready()` (Autoload order: GameManager=3, SaveManager=6) so settings are loaded **after** GameManager is ready. Need to call `TranslationServer.set_locale` in `SaveManager._load_settings()` or add a `locale_initialized` signal.

**Simpler solution:** Call `TranslationServer.set_locale(GameManager.settings["language"])` at the **end of `SaveManager._load_settings()`** since SaveManager initializes after GameManager and has access to GameManager.settings.

### Topic 3: Dynamic Label Pattern

**Problem:** Labels like `"SCORE: 1000"` mix translated prefix with runtime value.

**Solution (chosen):** Split into prefix + formatted value:
```
_score_label.text = "%s %d" % [tr("HUD_SCORE_PREFIX"), score]
```
Translation CSV:
```
HUD_SCORE_PREFIX,SCORE:,スコア:
```
This avoids format-string complexity in CSV and keeps each part independently translatable.

**Exception:** Static labels (e.g. pause title, button text) use plain `tr("KEY")`.

### Topic 4: How to Play — Overlay vs. New Scene

**Options evaluated:**
- **New scene** (`how_to_play.tscn`): Cleaner separation, but requires SceneManager integration and back-navigation
- **Overlay panel in main_menu.gd**: Simpler, no scene change needed, toggles visibility

**Chosen: Overlay panel.** The project's main_menu.gd already builds layout dynamically in code. Adding a hidden `Panel` child that shows on `[HOW TO PLAY]` press is consistent with this pattern and avoids adding a new scene to SceneManager routing.

### Topic 5: Parallelizable Tasks

- Translation CSV creation ← independent
- `GameManager` / `SaveManager` locale wiring ← independent of CSV content
- Each scene's `_refresh_labels()` ← independent of each other, depends on CSV being registered
- How to Play overlay ← depends on translation keys being defined
