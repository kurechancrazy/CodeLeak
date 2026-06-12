# クイズゲーム — ジャンルガイド

**次元:** UI 専用  
**genre-starters.md:** バンドル 4

---

## コアループ

問題文と選択肢を表示し、タイマー内に正解を選ぶ。
QuizQuestion Resource・タイマー・得点管理が核心。

---

## シーン階層

```
QuizGame (Node2D)
└── UI (CanvasLayer)
    ├── QuestionPanel (PanelContainer)
    │   ├── CategoryLabel (Label)
    │   ├── QuestionLabel (Label)
    │   └── TimerBar (ProgressBar)       — 残り時間を視覚化
    ├── ChoicesGrid (GridContainer)      — 2×2 に 4 択を配置
    │   ├── Choice_0 (Button)
    │   ├── Choice_1 (Button)
    │   ├── Choice_2 (Button)
    │   └── Choice_3 (Button)
    ├── FeedbackLabel (Label)            — ○ 正解！ / ✗ 不正解
    ├── ScoreLabel (Label)
    └── HintLabel (Label)               — ヒント表示（任意）
```

---

## 必須 Autoload

| Autoload | 役割 |
|---------|------|
| SaveManager | ハイスコア保存・ロード |
| ProgressManager | 全問正解・連続正解などの実績 |

---

## 主要実装パターン

### QuizQuestion Resource + QuizManager

```gdscript
# quiz_question.gd
class_name QuizQuestion
extends Resource

@export var category: String = ""
@export var question_text: String = ""
@export var choices: Array[String] = []
@export var correct_index: int = 0
@export var hint: String = ""
@export var time_limit: float = 10.0
@export var points: int = 100
```

```gdscript
# quiz_manager.gd（Node として QuizGame の子に置く）
class_name QuizManager
extends Node

@export var questions: Array[QuizQuestion] = []
@export var shuffle_on_start: bool = true

var _current_index: int = 0
var _score: int = 0
var _questions_shuffled: Array[QuizQuestion] = []

signal question_changed(q: QuizQuestion)
signal answered(is_correct: bool, correct_index: int)
signal quiz_finished(score: int, total: int)

func start() -> void:
    _questions_shuffled = questions.duplicate()
    if shuffle_on_start:
        _questions_shuffled.shuffle()
    _current_index = 0
    _score = 0
    _show_current_question()

func _show_current_question() -> void:
    if _current_index >= _questions_shuffled.size():
        quiz_finished.emit(_score, _questions_shuffled.size())
        return
    question_changed.emit(_questions_shuffled[_current_index])

func answer(choice_index: int) -> void:
    var q: QuizQuestion = _questions_shuffled[_current_index]
    var correct: bool = choice_index == q.correct_index
    if correct:
        _score += q.points
    answered.emit(correct, q.correct_index)
    _current_index += 1
```

### タイムアウト制御

```gdscript
# quiz_game.gd
extends Node2D

@onready var _timer_bar: ProgressBar = $UI/QuestionPanel/TimerBar
@onready var _manager: QuizManager = $QuizManager

var _time_remaining: float = 0.0
var _is_answering: bool = false

func _ready() -> void:
    _manager.question_changed.connect(_on_question_changed)
    _manager.answered.connect(_on_answered)

func _on_question_changed(q: QuizQuestion) -> void:
    _time_remaining = q.time_limit
    _timer_bar.max_value = q.time_limit
    _timer_bar.value = q.time_limit
    _is_answering = true

func _process(delta: float) -> void:
    if not _is_answering:
        return
    _time_remaining -= delta
    _timer_bar.value = _time_remaining
    if _time_remaining <= 0.0:
        _is_answering = false
        _manager.answer(-1)   # タイムアウト = 不正解扱い

func _on_choice_pressed(index: int) -> void:
    if not _is_answering:
        return
    _is_answering = false
    _manager.answer(index)
```

### フィードバック表示 + 次の問題へ

```gdscript
# quiz_game.gd（続き）
@onready var _feedback: Label = $UI/FeedbackLabel
@onready var _choices_grid: GridContainer = $UI/ChoicesGrid

var _choice_buttons: Array[Button] = []

func _gather_buttons() -> void:
    _choice_buttons.clear()
    for child: Node in _choices_grid.get_children():
        if child is Button:
            _choice_buttons.append(child as Button)

func _on_answered(is_correct: bool, correct_index: int) -> void:
    # 全ボタンを無効化して正解・不正解を色で示す
    for i: int in _choice_buttons.size():
        var btn: Button = _choice_buttons[i]
        btn.disabled = true
        if i == correct_index:
            btn.modulate = Color.GREEN
        elif btn.button_pressed:
            btn.modulate = Color.RED
    _feedback.text = "○ 正解！" if is_correct else "✗ 不正解"
    await get_tree().create_timer(1.5).timeout
    _reset_buttons()
    _manager._show_current_question()

func _reset_buttons() -> void:
    for btn: Button in _choice_buttons:
        btn.disabled = false
        btn.modulate = Color.WHITE
        btn.button_pressed = false
```

---

## よくある地雷

- `questions.shuffle()` で元の配列を変更すると問題順が毎回変わる → `duplicate()` してからシャッフルする
- `answer(-1)` をタイムアウト時に渡すと `correct_index` との比較で `-1 == correct_index` が意図せず真になり得る → `answer()` 内で `choice_index == -1` を先にチェックして不正解として即返す
- `TimerBar.max_value` を問題ごとに更新し忘れると、前の問題の時間制限が残り表示がおかしくなる
- 選択肢の数が `choices.size()` と `_choice_buttons.size()` で一致しない場合がある → `_ready()` で `_gather_buttons()` を呼び、ボタン数を問題生成時に合わせる
- `await` 中に次の問題ボタンが押されると二重回答になる → `_is_answering` フラグで確実にガードする

---

## 除外手順（このジャンルを使わない場合）

| 種別 | ファイル | 備考 |
|------|---------|------|
| ドキュメント | `docs/genres/quiz.md` | このファイル |
| Autoload | なし（コアのみ使用） | — |

project.godot から追加で削除するエントリなし（このジャンルは追加 Autoload を持たない）。
