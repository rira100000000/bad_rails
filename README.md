# BadBooks — 設計勉強会用 "あえて悪い" Rails アプリ

3年目 Rails エンジニア4人で **設計の勉強会** をするための題材アプリです。
ドメインは中古書籍フリマで、機能としては動きますが、内部設計は **意図的に悪く** 書いてあります。
このコードベースを題材に「何が悪く、どうリファクタすると良くなるか」を議論しながら学びます。

> ⚠️ **このリポジトリのコードを実プロダクトの参考にしないでください。** ほぼ全てがアンチパターンです。

---

## セットアップ

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
# → http://localhost:3000
```

### テスト
```bash
bundle exec rspec
```

### Seed ユーザー
| email | password |
|---|---|
| alice@example.com | password |
| bob@example.com   | password |
| carol@example.com | password |
| dave@example.com  | password |

---

## アプリの機能

- ユーザー: 登録 / ログイン / マイページ
- 書籍: 出品 / 編集 / 削除 / 検索 / 詳細
- 取引: 購入(モック決済)→ 発送 → 受取完了
- レビュー(取引完了後)
- お気に入り
- アプリ内通知

---

## 🗺 悪い設計マップ

コード中には `[BAD]` コメントで悪例の場所を明示してあります。 まずは各自で grep してみてください:

```bash
grep -rn "\[BAD\]" app/ db/ spec/ config/
```

### モデル層

| ファイル | 行付近 | 問題 | 違反している原則 |
|---|---|---|---|
| `app/models/user.rb` | 全体 (約140行) | God Object: 出品計算・購入計算・通知・統計・プレゼン整形・認可を全部抱える | **SRP**(単一責任) |
| `app/models/user.rb` | `total_sales_amount` | `each` で N+1。 税率 10% をハードコード | DRY / 効率 |
| `app/models/user.rb` | `rating_label` | 表示用文字列の整形が Model 内 | レイヤ分離 |
| `app/models/user.rb` | `after_create :send_welcome_email` | コールバックで同期メール送信 → 登録失敗の温床 | **コールバックハマリ** |
| `app/models/user.rb` | `grant_point_for_purchase!` | ポイント付与ロジックが User に。 ポリシー変更で User を毎回触る | SRP / OCP |
| `app/models/book.rb` | `STATUSES` + 文字列比較 | enum / state machine を使わず生文字列 | Primitive Obsession |
| `app/models/book.rb` | `shipping_fee` / `price_with_tax` | 同じ計算が複数箇所(Book, ApplicationController, OrdersController, View, Helper)に散在 | **DRY** |
| `app/models/book.rb` | `Book.search` | `where("title LIKE '%#{keyword}%'")` で文字列補間 | **セキュリティ(SQLi)** |
| `app/models/book.rb` | `after_save :notify_price_changed` | 価格更新で毎回通知 → 仕様変更しづらい | コールバック濫用 |
| `app/models/order.rb` | `after_create` 2発 | OrdersController でも同じ通知を作るので **二重通知** バグ | 副作用の散在 |
| `app/models/order.rb` | `cancel!` | book の状態戻しと order 更新が **別トランザクション** | 一貫性 |
| `app/models/concerns/misc.rb` | 全体 | 関係ない関数を Concern にまとめた kitchen sink | Concern の濫用 |

### コントローラ層

| ファイル | 行付近 | 問題 | 違反している原則 |
|---|---|---|---|
| `app/controllers/application_controller.rb` | `calc_total_with_tax` / `calc_shipping_fee` | 税・送料ロジックが ApplicationController にも(全部で5箇所目) | **DRY** |
| `app/controllers/application_controller.rb` | `before_action :require_login, except: ...` | except での一括指定。 派生 Controller で `skip_before_action` 連発 | OCP / 認可設計 |
| `app/controllers/users_controller.rb` | `create` | `params[:user].permit!` で **mass assignment 抜け穴**。 admin にも設定可能 | **セキュリティ** |
| `app/controllers/users_controller.rb` | `show` | `current_user.stats` 呼び出しで N+1 連鎖 | パフォーマンス |
| `app/controllers/books_controller.rb` | `index` | `where("title LIKE '%#{q}%'")` で **SQL Injection** の余地 | **セキュリティ** |
| `app/controllers/books_controller.rb` | `edit` / `update` / `destroy` | **認可チェックなし** → 他人の出品も編集・削除可能 | **認可(IDOR)** |
| `app/controllers/books_controller.rb` | `create` | `params[:book].to_unsafe_h` → seller_id 偽装可能 | mass assignment |
| `app/controllers/books_controller.rb` | `favorite` | 重複登録チェックなし → 同じ本に何度でも favorite | データ整合性 |
| `app/controllers/books_controller.rb` | `buy` | OrdersController#create とほぼ同じ処理。 しかも税率8%・送料カットオフが異なる | **重複実装** |
| `app/controllers/orders_controller.rb` | `create` (約60行) | The Fat Controller。 在庫(=status)チェック → 税計算 → 送料計算 → Order保存 → Book更新 → ポイント付与 → 通知 → メール → ログ をすべて直書き | **SRP / 凝集度** |
| `app/controllers/orders_controller.rb` | `create` | Order作成と Book更新が **別トランザクション** → 途中失敗で不整合 | **トランザクション境界** |
| `app/controllers/orders_controller.rb` | `create` | Notification.create! と Order の after_create による **通知二重送信** | 副作用の散在 |
| `app/controllers/orders_controller.rb` | `create`/`receive` | ポイント付与が **3箇所** (User, OrdersController#create, OrdersController#receive) で挙動が違う | DRY / 仕様乖離 |
| `app/controllers/orders_controller.rb` | `show` | **認可チェックなし** → 注文IDを直接叩けば他人の注文を見られる | IDOR |
| `app/controllers/orders_controller.rb` | `pay` / `ship` / `receive` | 状態遷移の事前チェックなし | 状態遷移の破壊 |
| `app/controllers/reviews_controller.rb` | `create` | 状態チェックなし → `received` でない注文にレビュー可能 | ビジネスルール |

### View層

| ファイル | 行付近 | 問題 | 違反している原則 |
|---|---|---|---|
| `app/views/books/index.html.erb` | each ブロック | `book.seller.average_rating` を view 内で呼ぶ → **N+1** | クエリ設計 |
| `app/views/books/index.html.erb` | 価格表示の if-elsif | 送料計算ロジックが View に。 もはや4箇所目 | DRY |
| `app/views/books/show.html.erb` | 価格表示 | `display_price` と `number_to_currency` を同じページで併用 → 表示が割れる | 一貫性 |
| `app/views/books/show.html.erb` | `if @book.status == "listed"` | View で status の文字列比較 | Primitive Obsession |
| `app/views/users/show.html.erb` | listings ループ | `b.order.buyer.name` で **N+1 連鎖** | クエリ設計 |
| `app/views/orders/index.html.erb` | sales ループ | book → order の N+1 | クエリ設計 |
| `app/helpers/application_helper.rb` | `unread_count_for` | helper 内で DB アクセス → View 描画中に SQL 飛ぶ | レイヤ分離 |
| `app/helpers/application_helper.rb` | `book_status_label` | Book#status_label と二重実装 | DRY |

### その他

| ファイル | 問題 |
|---|---|
| `app/models/concerns/misc.rb` | "なんとなく共通っぽい関数" を集めただけの Concern。 include 先で何が混ざるか分からない |
| `db/seeds.rb` | seed が冪等でない。 `delete_all` で消してから入れ直す方式 |
| `spec/requests/orders_flow_spec.rb` | "2つの購入経路で合計金額が違う" ことを **正常系扱い** にしているテスト(現状追認) |

---

## 🎓 リファクタリング演習スケジュール(全6回想定)

### Step 1 — Fat Controller を薄くする
**お題**: `OrdersController#create` を15行以内に収める。

- 抽出方法の選択肢を議論
  - **Service Object** (`app/services/orders/place_order.rb`)
  - **Form Object** (`OrderForm`)
  - **Command パターン**
- 副作用(通知, メール, ログ)の責務はどこ?
- トランザクション境界をどこに引くか
- 学ぶ原則: **SRP, トランザクション境界, 副作用の分離**

### Step 2 — Primitive Obsession を Value Object へ
**お題**: `Book#price` の扱いを `Money` 型に置き換える。

- 円・税込・送料を **Value Object** で表現
- 計算ロジックの集約(税率・送料の5箇所散在を1箇所に)
- 学ぶ原則: **Primitive Obsession, Value Object, DRY**

### Step 3 — 状態管理を state machine 化
**お題**: `Book#status` と `Order#status` を `enum` + `AASM`(または自前state machine)で整理。

- 状態遷移メソッドの一元化
- View / Controller の文字列比較を排除
- 不正遷移のガード
- 学ぶ原則: **状態機械, テル・ドント・アスク**

### Step 4 — N+1 退治と Query Object
**お題**: `BooksController#index`, `users/show`, `orders/index` の N+1 を解消。

- `includes` の入れ方
- "検索条件" の組み立てを **Query Object** (`app/queries/book_search.rb`) に
- SQL Injection の修正
- 学ぶ原則: **Query Object, セキュア by default**

### Step 5 — 認証・認可の整理
**お題**: 認可ロジックを Pundit / 自前 Policy へ移行。

- Strong Parameters 導入で mass assignment 修正
- `Pundit` の Policy クラスを Books/Orders/Reviews に
- Controller から `current_user.id == book.seller_id` 等を追放
- 学ぶ原則: **認可の集約, IDOR 対策**

### Step 6 — 副作用(通知・メール)の分離
**お題**: コールバック地獄を排除し、明示的なドメインイベントへ。

- after_create でのメール送信を ActiveJob に
- 通知作成を `Notification::Notifier` に集約 (二重通知バグも解決)
- 学ぶ原則: **副作用の制御, ドメインイベント, ジョブ化**

---

## 📚 想定到達点 (After のスケッチ)

```
app/
├── models/
│   ├── book.rb            # 状態は enum、計算ロジックは Money に委譲
│   ├── order.rb           # 状態遷移メソッドのみ。 副作用は呼ばない
│   ├── user.rb            # 認証と関連定義のみ。 統計は外部 Query へ
│   └── value_objects/
│       └── money.rb
├── services/
│   └── orders/
│       ├── place_order.rb # トランザクション境界をここに
│       └── ship_order.rb
├── queries/
│   ├── book_search.rb
│   └── user_statistics.rb
├── policies/
│   ├── book_policy.rb
│   └── order_policy.rb
└── notifiers/
    └── purchase_notifier.rb
```

---

## 🧭 ファシリテーター向けメモ

- **1回 60〜90分** が目安。 1 Step に1回使うか、2 Step まとめて議論
- **TDD で進める**: まず壊れない網を `spec/` に追加 → 安全にリファクタ
- **議論のフックワード**:
  - 「もしこの仕様が変わったら、何箇所触る?」
  - 「このメソッドのテスト、いくつのモックがいる?」
  - 「これはモデル/コントローラ/サービス/ヘルパー どこに置くのが自然?」
- 最初の1回は **アプリを触ってバグを発見してもらう** ところから始めるとモチベが上がる
  - 例: 「BooksController#buy 経由」と「カート確認画面 (OrdersController#create) 経由」で合計金額が違うバグ

---

## 🔗 参考文献

- Sandi Metz "Practical Object-Oriented Design in Ruby"
- 渡辺 直人 "Rails 解体新書"
- "Layered Design for Ruby on Rails Applications"
- Martin Fowler "Refactoring"
- Bryan Helmkamp "7 Patterns to Refactor Fat ActiveRecord Models"

---

## 🪪 ライセンス / 利用範囲

社内勉強会の教材として作成。 自由に fork / 改変してご利用ください。
