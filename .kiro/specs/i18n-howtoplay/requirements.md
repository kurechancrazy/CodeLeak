# Requirements — Bilingual Support (EN/JA) & How to Play

## Project Description

Add English/Japanese bilingual support to AI Code Leak with English as the primary language, plus a "How to Play" screen accessible from the main menu so players understand the gameplay.

---

## Requirement 1: Translation System

### 1.1 Translation File

When the game initializes, the system shall load translations from `assets/i18n/translations.csv` covering all UI strings in both English (`en`) and Japanese (`ja`).

**Acceptance Criteria:**
- The system shall provide an `en` column and a `ja` column in the CSV
- The system shall register the translation file via Godot's Localization project settings
- When `TranslationServer.get_locale()` returns `"en"`, `tr("KEY")` shall return the English string
- When `TranslationServer.get_locale()` returns `"ja"`, `tr("KEY")` shall return the Japanese string

### 1.2 Default Language

When the game starts for the first time (no saved language preference), the system shall default to English (`"en"`).

**Acceptance Criteria:**
- The system shall apply `"en"` locale on first launch when no preference is saved
- The system shall apply the saved locale on subsequent launches

---

## Requirement 2: Localized UI Strings

### 2.1 Main Menu

When the main menu is displayed, the system shall show all labels in the current locale.

**Acceptance Criteria:**
- The system shall translate: game subtitle, `[PLAY]` button, `[HOW TO PLAY]` button, `[QUIT]` button

### 2.2 Game HUD

When a puzzle is active, the system shall display HUD labels in the current locale.

**Acceptance Criteria:**
- The system shall translate: `SCORE:`, `HINTS:`, `LEVEL` label prefix

### 2.3 Investigation Panel

When the investigation panel is displayed, the system shall show all interactive labels in the current locale.

**Acceptance Criteria:**
- The system shall translate: `[HINT]` button, correct answer feedback text (`>> PATCHED`), wrong answer feedback text (`>> ACCESS DENIED`)

### 2.4 Pause Menu

When the pause menu is displayed, the system shall show all labels in the current locale.

**Acceptance Criteria:**
- The system shall translate: pause title, `[RESUME]`, `[RESTART LEVEL]`, `[MAIN MENU]` buttons

### 2.5 Result Screen

When the result screen is displayed, the system shall show all labels in the current locale.

**Acceptance Criteria:**
- The system shall translate: analysis complete title, `SCORE:`, `TIME:`, `MISS:`, `HINTS USED:`, `>> NEW HIGH SCORE!`, `[RETRY]`, `[MAIN MENU]` buttons

### 2.6 SYSTEM SECURED Overlay

When the level-clear animation plays, the system shall display the secured message in the current locale.

**Acceptance Criteria:**
- The system shall translate: `[SYSTEM SECURED]` typewriter text

---

## Requirement 3: Language Selection

### 3.1 Language Toggle on Main Menu

When the main menu is displayed, the system shall show a language toggle button (e.g., `[EN] / [JA]`) that switches between English and Japanese.

**Acceptance Criteria:**
- The system shall display the toggle in the top-right area of the main menu
- When the player activates the toggle, the system shall switch locale immediately and refresh all visible labels without scene reload
- The toggle label shall always show the current active locale

### 3.2 Language Persistence

When the player changes the language, the system shall save the preference via `SaveManager` and restore it on the next launch.

**Acceptance Criteria:**
- The system shall store the language preference under `settings` / `language` in the save file
- The system shall call `TranslationServer.set_locale()` with the restored value on `GameManager._ready()`

---

## Requirement 4: How to Play Screen

### 4.1 How to Play Entry Point

When the main menu is displayed, the system shall show a `[HOW TO PLAY]` button that opens the How to Play screen.

**Acceptance Criteria:**
- The system shall display a `[HOW TO PLAY]` button on the main menu below `[PLAY]`
- When the player activates the button, the system shall show the How to Play overlay/screen

### 4.2 How to Play Content

When the How to Play screen is displayed, the system shall present clear gameplay instructions in the current locale.

**Acceptance Criteria:**
- The system shall explain: the game premise (AI-generated code with hidden malicious logic)
- The system shall explain: how to read the code panel (left side)
- The system shall explain: how to answer questions in the investigation panel (right side)
- The system shall explain: what hints do and how to use them
- The system shall explain: scoring (time bonus, miss penalty)
- The system shall display this content in both English and Japanese based on locale

### 4.3 How to Play Dismissal

When the How to Play screen is displayed, the system shall allow the player to close it and return to the main menu.

**Acceptance Criteria:**
- The system shall show a `[CLOSE]` / `[BACK]` button
- When the player presses `cancel` (Escape) or the close button, the system shall return to the main menu
- The system shall NOT navigate away from the main menu on close (stay on main menu)

---

## Requirement 5: Label Refresh on Locale Change

### 5.1 Dynamic Label Update

When the locale changes at runtime, the system shall refresh all currently visible UI labels without requiring a scene reload.

**Acceptance Criteria:**
- The system shall emit `EventBus.settings_changed.emit("language", locale)` when locale changes
- All active scenes that display localizable text shall connect to this signal and update their labels
- The system shall update labels within the same frame the signal is received
