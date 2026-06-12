# Security — 機密データ・セキュリティ基準

## 機密データの分類

| データ種類 | 機密度 | 保存方法 |
|----------|--------|---------|
| ハイスコア・進行状況 | 低 | ConfigFile（平文） |
| 設定値 | 低 | ConfigFile（平文） |
| 購入状態・ライセンス | 高 | 暗号化ファイル |
| APIキー・認証トークン | 最高 | サーバーサイドのみ（クライアントに持たせない） |

---

## 購入状態の検証

購入状態はローカルフラグだけで判定しない。

```
起動時
  → IAP プラットフォーム SDK でサーバー検証
  → 検証済み結果を GameManager に反映
  → 検証失敗 → プレミアム機能を無効化

購入フロー
  → IAP SDK 経由で購入
  → レシート検証（サーバーサイド推奨）
  → 検証成功後にローカル状態を更新
```

---

## 暗号化ファイルの使用

Godot 4 には組み込みの暗号化ファイルI/Oがある。

```gdscript
# ✅ FileAccessEncrypted を使った暗号化保存
func _save_sensitive_data(data: Dictionary) -> void:
    var key: PackedByteArray = _get_encryption_key()
    var file: FileAccessEncrypted = FileAccessEncrypted.new()
    var base_file: FileAccess = FileAccess.open("user://sensitive.dat", FileAccess.WRITE)
    if base_file == null:
        Logger.error("Failed to open file for encryption")
        return
    var err: Error = file.open_and_parse(base_file, FileAccessEncrypted.MODE_WRITE_AES256, key)
    if err != OK:
        Logger.error("Encryption failed", {"error": err})
        return
    file.store_string(JSON.stringify(data))
    file.close()

func _get_encryption_key() -> PackedByteArray:
    # キーはビルド時に埋め込む（完全な保護ではないが、平文よりは安全）
    # 本番ではより安全なキー管理を検討する
    var key_str: String = OS.get_unique_id()  # デバイス固有ID
    return key_str.to_utf8_buffer().slice(0, 32)
```

---

## APIキーの管理

```gdscript
# ❌ ソースコードへの直書き（絶対禁止）
const API_KEY: String = "sk-xxx..."  # 禁止

# ✅ エクスポート設定の機能でビルド時に埋め込む（最終手段）
# Project Settings → Export → Features に環境変数を設定

# ✅ 推奨: APIキーを必要とするロジックはサーバーサイドに移す
# クライアントはサーバーAPI経由でのみアクセス
```

---

## 権限の最小化

エクスポート設定で宣言する権限は必要最小限。

```
不要な権限:
❌ インターネットアクセス（オフラインゲームの場合）
❌ カメラ（使わない場合）
❌ 位置情報（使わない場合）
❌ 連絡先（ゲームには不要）
```

---

## セキュリティチェックリスト

```
□ APIキー・シークレットがソースコードに含まれていないか
□ 購入状態の検証がサーバーサイドで行われているか
□ 機密データが平文の ConfigFile に保存されていないか
□ 不要な権限をリクエストしていないか
□ ユーザー入力を適切にサニタイズしているか（SQLインジェクション等）
```
