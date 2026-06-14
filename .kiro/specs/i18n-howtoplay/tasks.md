# Tasks — Bilingual Support (EN/JA) & How to Play

## Overview

| # | Task | Dependency |
|---|------|-----------|
| 1 | Create translation CSV and register it in project.godot | none |
| 2 | Wire locale initialization in GameManager and SaveManager | none |
| 3 | Localize main_menu.gd: language toggle + How to Play overlay | 1, 2 |
| 4 | Localize in-game scenes: HUD, InvestigationPanel, game_screen | 1, 2 |
| 5 | Localize pause_menu.gd | 1, 2 |
| 6 | Localize result_screen.gd | 1, 2 |

Requirement coverage: 1.1, 1.2, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.1, 3.2, 4.1, 4.2, 4.3, 5.1

Tasks 1 and 2 are independent (P). Tasks 3–6 are independent of each other and can run in parallel after 1 and 2 complete (P).

---

## Task 1: Create translation CSV and register it in project.godot (P)

> Requirements: 1.1

Create `assets/i18n/translations.csv` with `key,en,ja` columns containing all 35 translation keys defined in the design (main menu, HUD, investigation panel, pause menu, result screen, system secured, how to play sections). Register the file in `project.godot` under `[internationalization] / locale/translations`.

- [x] 1.1 Create `assets/i18n/` directory and write `translations.csv` with all keys from the design's translation key table; add the `[internationalization]` section to `project.godot` pointing to `res://assets/i18n/translations.csv`

---

## Task 2: Wire locale initialization in GameManager and SaveManager (P)

> Requirements: 1.2, 3.2

Two small changes: change the default language in `GameManager.settings` from `"ja"` to `"en"`, and call `TranslationServer.set_locale()` in two places so the correct locale is active from boot and whenever the player changes the language.

- [x] 2.1 In `autoloads/game_manager.gd`, change `settings["language"]` default from `"ja"` to `"en"`; in `_on_settings_changed()`, add a branch for `key == "language"` that calls `TranslationServer.set_locale(value as String)`

- [x] 2.2 In `autoloads/save_manager.gd`, add `TranslationServer.set_locale(GameManager.settings["language"])` at the end of `_load_settings()` so the restored locale is applied before any scene renders

---

## Task 3: Localize main_menu.gd — language toggle + How to Play overlay

> Requirements: 2.1, 3.1, 3.2, 4.1, 4.2, 4.3, 5.1
> Dependency: Task 1, Task 2

The most substantial task. Adds three things to `main_menu.gd`: (a) replace all static strings with `tr()` calls and add `_refresh_labels()`; (b) a language toggle button in the top-right corner; (c) a How to Play overlay panel that covers the screen and contains the gameplay instructions with a close button.

- [x] 3.1 Store label/button references as fields (`_subtitle_label`, `_play_btn`, `_htp_btn`, `_quit_btn`, `_lang_btn`); replace all hardcoded text in `_build_layout()` with `tr()` calls; add `_refresh_labels()` that re-applies `tr()` to every stored reference; connect `EventBus.settings_changed` → call `_refresh_labels()` when `key == "language"`

- [x] 3.2 Add a language toggle button (`_lang_btn`) anchored to the top-right corner of the screen; pressing it reads the current locale from `GameManager.settings["language"]`, toggles between `"en"` and `"ja"`, and calls `GameManager.update_setting("language", new_locale)`; the button label always reflects the locale the player will switch *to* (e.g. shows `[JA]` when current locale is `en`)

- [x] 3.3 Build a How to Play overlay panel (`_htp_overlay`) that fills the screen, starts hidden, and contains: title label, five section blocks (MISSION, CODE PANEL, INVESTIGATION PANEL, HINTS, SCORING) each with a bold title and a description line, and a `[CLOSE]` button; all strings use `tr()`; the overlay is shown when `[HOW TO PLAY]` is pressed and hidden when `[CLOSE]` is pressed or the player presses the `cancel` input action; `_refresh_labels()` also updates the overlay's labels

---

## Task 4: Localize in-game scenes — HUD, InvestigationPanel, game_screen (P)

> Requirements: 2.2, 2.3, 2.6, 5.1
> Dependency: Task 1, Task 2

Three small changes across in-game files that don't require a full `_refresh_labels()` pattern because their text is always set reactively (on puzzle load / on answer / on animation start).

- [x] 4.1 In `scenes/ui/game_hud.gd`: store references to `_score_label`, `_hints_label`; in `_on_puzzle_loaded()` replace `"SCORE: 1000"` with `"%s %d" % [tr("HUD_SCORE_PREFIX"), 1000]` and `"HINTS: |||"` with `"%s |||" % tr("HUD_HINTS_PREFIX")`; in `_on_answer_submitted()` and `_on_hint_applied()` use the same prefix pattern; add `_refresh_labels()` for the static HUD text (level prefix) and connect `EventBus.settings_changed`

- [x] 4.2 In `scenes/game/investigation_panel.gd`: replace `_hint_button.text = "[HINT]"` with `_hint_button.text = tr("BTN_HINT")`; replace `">> PATCHED\n   %s" % explanation` with `"%s\n   %s" % [tr("FEEDBACK_PATCHED"), explanation]`; replace `">> ACCESS DENIED"` with `tr("FEEDBACK_DENIED")`; connect `EventBus.settings_changed` to refresh `_hint_button.text` when language changes

- [x] 4.3 In `scenes/game/game_screen.gd`: in `_play_secured_sequence()`, replace the hardcoded `"[SYSTEM SECURED]"` string with `tr("SYSTEM_SECURED")` so the typewriter uses the current-locale text

---

## Task 5: Localize pause_menu.gd (P)

> Requirements: 2.4, 5.1
> Dependency: Task 1, Task 2

Store button/label references in `pause_menu.gd` and add `_refresh_labels()` so the pause menu updates immediately if the player changes language from the main menu before pausing.

- [x] 5.1 In `scenes/ui/pause_menu.gd`: store references to the title label and the three buttons (`_resume_btn`, `_restart_btn`, `_main_menu_btn`); replace all `text = "..."` literals with `tr()` calls in `_build_menu()`; add `_refresh_labels()` that re-applies `tr()` to every stored reference; connect `EventBus.settings_changed` → call `_refresh_labels()` when `key == "language"`; disconnect in `_exit_tree()`

---

## Task 6: Localize result_screen.gd (P)

> Requirements: 2.5, 5.1
> Dependency: Task 1, Task 2

Apply the split-prefix pattern to the dynamic labels on the result screen and add `_refresh_labels()`.

- [x] 6.1 In `scenes/ui/result_screen.gd`: replace `"// ANALYSIS COMPLETE"` with `tr("RESULT_TITLE")`; replace the score/time/miss/hints-used labels using the split-prefix pattern (`"%s %d" % [tr("RESULT_SCORE_PREFIX"), _result_score]` etc.); replace `">> NEW HIGH SCORE!"` with `tr("RESULT_NEW_HIGH")`; replace button texts with `tr("BTN_RETRY")` and `tr("BTN_MAIN_MENU")`; add `_refresh_labels()` that rebuilds all label texts using current locale and stored result data; connect `EventBus.settings_changed` → call `_refresh_labels()` when `key == "language"`; disconnect in `_exit_tree()`
