# BadBooks — 設計勉強会用 "あえて悪い" Rails アプリ

 **設計の勉強会** をするための題材アプリです。
ドメインは中古書籍フリマで、機能としては動きますが、内部設計は **意図的に悪く** 書いてあります。

> ⚠️ **このリポジトリのコードを実プロダクトの参考にしないでください。** ほぼ全てがアンチパターンです。

---

## 進め方

コード中のアンチパターンには **`[BAD-NNN]` の番号のみ** が打たれており、何が悪いかは書いていません。
番号の解説はこの README の「**🪤 アンチパターン番号引き**」セクションにあります。

### 推奨ワークフロー

1. まずアプリを `bin/rails server` で立ち上げて触ってみる
2. ペア / グループに分かれて、コードを読みながら `[BAD-NNN]` を発見する
3. **README を見る前に**、各 `[BAD-NNN]` が何故悪いのかを各自で言語化する
4. 答え合わせとして README の番号引きを参照
5. リファクタリング演習(後述)を進める

```bash
# 全 [BAD] マーカーを一覧する
grep -rn "\[BAD-" app/ db/ spec/ config/
```

---

## セットアップ

### ローカル (Ruby 3.4.8)

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
# → http://localhost:3000
```

### Docker

勉強会で各自のローカルに Ruby を入れたくない場合はこちら。 開発モード(`RAILS_ENV=development`) で起動します。

```bash
docker compose up --build
# → http://localhost:3000
```

- 初回起動時に `db:prepare`(schema load + seed)が走るので、 seed ユーザでそのままログイン可。
- ソースは bind mount されているのでホスト側の編集が即反映される。
- DB(SQLite) はホストの `storage/` に作られる。 リセットしたければ `storage/development.sqlite3` を削除して再起動。
- gem は名前付き volume `bundle` に入る。 Gemfile を変更したら `docker compose build` で入れ直す。

コンテナ内でコマンドを叩きたいとき:

```bash
docker compose exec web bin/rails console
docker compose exec web bundle exec rspec
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

## 🪤 アンチパターン番号引き

### `app/models/user.rb`

| ID | 何が悪いか | 違反している原則 |
|---|---|---|
| **BAD-001** | クラスコメント。 User がアプリの全ドメイン知識(出品計算・購入計算・通知・統計・プレゼン整形・認可・ポイント・メール)を抱える **God Object**。 | SRP |
| **BAD-002** | `has_many` が爆発。 User がドメインの中心だと錯覚させ、 改修時に必ず User を触る羽目になる。 | SRP / 凝集度 |
| **BAD-003** | email の正規表現を直書きで埋め込み。 メンテ困難 & 仕様変更時に他の箇所と乖離する。 | DRY / メンテ性 |
| **BAD-004** | `after_create` でメール送信(同期)。 メール失敗で登録ごとロールバック、テストで実メール送信、デバッグ困難。 | コールバックハマり / 副作用の制御 |
| **BAD-005** | `after_save` で通知を作成。 更新の度に通知レコードが増殖する温床。 | 副作用の制御 |
| **BAD-006** | 売上合計を `each` ループで集計しつつ、税率 10% をハードコード。 N+1 + マジックナンバー + DRY 違反(税率は他に4箇所)。 | DRY / マジックナンバー |
| **BAD-007** | `purchases.each { |o| s += o.total_price }`。 SQL `SUM` でいい処理を Ruby で。 | パフォーマンス |
| **BAD-008** | `can_buy?` という認可ロジックを User が持つ。 Book との相互参照で双方向依存。 | Tell, Don't Ask / 認可の集約 |
| **BAD-009** | `average_rating` が view から呼ばれて N+1 を量産。 集計クエリにすべき。 | パフォーマンス / クエリ設計 |
| **BAD-010** | 表示用の星マーク文字列を Model が返す。 プレゼンテーション層のロジックがモデルに漏れている。 | レイヤ分離 |
| **BAD-011** | `notify!` で User が Notification の生成方法を直接知っている。 通知ポリシーが変わると User を触る。 | 依存の向き / OCP |
| **BAD-012** | ポイント付与ロジック(`+ (total * 0.01) + 10`)が User に。 ポイント仕様変更で User を触る。 さらに OrdersController と挙動が違う。 | SRP / DRY |
| **BAD-013** | 統計用ハッシュを返す `stats` メソッド。 View と Controller の両方で使われ、 内部キーが密結合。 | レイヤ分離 / 凝集度 |
| **BAD-014** | `display_name`(管理者プレフィックス)が Model に。 これも View ヘルパーで扱うべき表示整形。 | レイヤ分離 |
| **BAD-015** | `User.authenticate` クラスメソッドはあるが、 SessionsController では `find_by + authenticate` を直書き(BAD-044 参照)。 同じ認証経路が二重実装。 | DRY |

### `app/models/book.rb`

| ID | 何が悪いか | 違反している原則 |
|---|---|---|
| **BAD-016** | クラスコメント。 商品・在庫・出品・価格計算・表示整形を Book が一手に持つ。 | SRP |
| **BAD-017** | `status` を **生の文字列** で保持。 enum / state machine を使わず、 全レイヤーに `== "sold"` のような比較が散らかる原因。 | Primitive Obsession |
| **BAD-018** | `scope :listed` などと、 `where(status: "listed")` のベタ書きが Controller/View に併存。 検索条件の根拠が複数。 | DRY |
| **BAD-019** | `after_save :notify_price_changed` で、 価格更新の度に出品者へ通知。 「値下げ通知」と「内部修正」が区別できない。 | 副作用の制御 |
| **BAD-020** | `price_with_tax` の税率 10% ハードコード。 ApplicationController/View/Helper/OrdersController と合わせて **税計算が5箇所** に散らばる。 | DRY |
| **BAD-021** | 送料計算ロジック。 ApplicationController/View/OrdersController/BooksController と合わせて **送料計算が5箇所** に散らばり、 しかも閾値・金額が乖離(下記 BAD-043, BAD-054, BAD-060, BAD-080 参照)。 | DRY / 仕様乖離 |
| **BAD-022** | `display_price` という金額整形が Model に。 View ヘルパー(BAD-072)とも二重実装。 | レイヤ分離 / DRY |
| **BAD-023** | `status_label`(日本語表示)が Model に。 ApplicationHelper(BAD-074)と二重実装。 | レイヤ分離 / DRY |
| **BAD-024** | `mark_as_sold!` 等の状態遷移メソッドが Model にあるのに、 OrdersController では `status = "sold"` を直書きする箇所も(BAD-062)。 一貫性なし。 | DRY |
| **BAD-025** | `Book.search` で `where("title LIKE '%#{keyword}%'")` と **文字列補間** している → **SQL Injection** の余地あり。 | セキュリティ |

### `app/models/order.rb`

| ID | 何が悪いか | 違反している原則 |
|---|---|---|
| **BAD-026** | Order だがビジネスロジックの大半は OrdersController に逃げており、 一方で状態管理メソッドはここにもある。 責務が中途半端。 | SRP |
| **BAD-027** | `scope :paid` 等と、 OrdersController での文字列比較が併存。 状態文字列の参照点が散在。 | DRY |
| **BAD-028** | `after_create` でメール送信(同期)。 トランザクション境界が曖昧、 注文保存失敗時の挙動が複雑化。 | 副作用の制御 |
| **BAD-029** | `after_create` で通知作成。 だが OrdersController#create でも同種の通知を作っている(BAD-064)→ **二重通知バグ**。 | 副作用の散在 |
| **BAD-030** | `reviewable?` 判定が View / Controller / Model の複数箇所にあり、 仕様変更時に追従漏れが出る。 | DRY |
| **BAD-031** | `cancel!` で Order 更新と Book の状態戻しが **トランザクション無しで連続実行**。 中間失敗で不整合。 | トランザクション境界 |

### `app/models/review.rb`

| ID | 何が悪いか | 違反している原則 |
|---|---|---|
| **BAD-032** | rating の数値範囲はバリデーションで担保しているが、 View で `if rating == 5` のような分岐が散らかる呼び水。 値オブジェクト(`Rating`)にすべき。 | Primitive Obsession |
| **BAD-033** | レビュー作成時に評価サマリを **集計していない**。 結果として User#average_rating が毎回フルスキャン。 集計テーブル or counter cache の検討対象。 | パフォーマンス |

### `app/models/favorite.rb`

| ID | 何が悪いか | 違反している原則 |
|---|---|---|
| **BAD-034** | `(user_id, book_id)` のユニーク制約も、 アプリ側の重複チェックも無し。 同一ブックの favorite が無限に増える。 | データ整合性 |

### `app/models/concerns/misc.rb`

| ID | 何が悪いか | 違反している原則 |
|---|---|---|
| **BAD-035** | "なんとなく共通っぽい関数" を集めただけの kitchen sink な Concern。 include する側で何が混ざるか分からない、 命名 `Misc` 自体が責務を放棄している。 | Concern の濫用 / SRP |
| **BAD-036** | `included do` 内で `scope` を勝手に生やしている。 include した側のクラスに副作用を埋め込む。 | 副作用の制御 |
| **BAD-037** | `adult?(birth_date)` という User 専用っぽいメソッドが Concern に紛れ込んでいる。 含めるべきクラスが分からない。 | SRP |

### `app/controllers/application_controller.rb`

| ID | 何が悪いか | 違反している原則 |
|---|---|---|
| **BAD-038** | ApplicationController が認証・認可・フラッシュ・税計算・送料計算ヘルパーまで抱える。 | SRP |
| **BAD-039** | Rails 7.1 のコールバックアクション検証 (`raise_on_missing_callback_actions`) を切ってしまっている。 設計の歪み(except 列挙)を黙らせるためだけの対症療法。 | 対症療法的設定 |
| **BAD-040** | `before_action :require_login, except: [...]` の except 一括指定。 派生 Controller で `skip_before_action` を連発する羽目になり、 認可ポリシーが追えなくなる。 | OCP / 認可設計 |
| **BAD-041** | `current_user` の memo 化ロジックが Controller に直書き。 セッション周りを再利用するたびにコピペ。 | DRY |
| **BAD-042** | 税計算ヘルパーが ApplicationController に(税計算は全5箇所目)。 helper_method で View からも呼べてしまうので散らかりが加速。 | DRY |
| **BAD-043** | 送料計算がここにも。 しかも閾値が **4980円** で、 Book#shipping_fee(5000円)と OrdersController(2000/5000円)と乖離している。 | DRY / 仕様乖離 |

### `app/controllers/sessions_controller.rb`

| ID | 何が悪いか | 違反している原則 |
|---|---|---|
| **BAD-044** | `User.authenticate`(BAD-015)を使わず `find_by + authenticate` を直書き。 認証経路が二重に存在。 | DRY |
| **BAD-045** | ログイン失敗時のメッセージで「メアド未登録」と「パスワード違い」を **区別している**。 アカウント列挙攻撃の手助けになる。 | セキュリティ |

### `app/controllers/users_controller.rb`

| ID | 何が悪いか | 違反している原則 |
|---|---|---|
| **BAD-046** | `params[:user].permit!` で **mass assignment 全許可**。 任意ユーザが `admin=true` で登録可能。 | セキュリティ |
| **BAD-047** | `show` で `stats` を呼ぶことで N+1 を連鎖発火(BAD-006/BAD-007/BAD-009 を全部経由)。 | パフォーマンス |

### `app/controllers/books_controller.rb`

| ID | 何が悪いか | 違反している原則 |
|---|---|---|
| **BAD-048** | 検索条件を文字列補間で組み立て → **SQL Injection** の余地。 `where("LIKE '%#{q}%'")` パターン。 | セキュリティ |
| **BAD-049** | `@books` を `includes` しないまま view に渡している → view の各種 `book.seller.xxx` で N+1 が確定。 | パフォーマンス |
| **BAD-050** | `to_unsafe_h` で **mass assignment 全許可**。 `seller_id` を任意指定して他人名義での出品が可能。 | セキュリティ |
| **BAD-051** | `edit` / `update` / `destroy` に **認可チェックなし**。 ID を直叩きすれば **他人の出品の編集・削除が可能** (IDOR)。 | 認可 / IDOR |
| **BAD-052** | favorite で **重複登録チェックなし**。 同じ書籍に何度でも favorite できる。 | データ整合性 |
| **BAD-053** | この `buy` アクションが OrdersController#create と機能重複。 同じ「購入」の道が2本ある。 | SRP / DRY |
| **BAD-054** | しかも `buy` の税率は **8%**、送料閾値は **3000円で400円**。 OrdersController(税10%/送料閾値2000円で250円) と **同じ操作なのに合計金額が違う** バグ。 | 仕様乖離 |

### `app/controllers/orders_controller.rb`

| ID | 何が悪いか | 違反している原則 |
|---|---|---|
| **BAD-055** | クラスコメント相当。 Fat Controller の見本市。 認可・在庫・税・送料・状態遷移・通知・メール・ログ・ポイントが1つの `create` に同居。 | SRP |
| **BAD-056** | `index` で `@purchases` / `@sales` を `includes` しないで view に渡す → N+1 確定。 | パフォーマンス |
| **BAD-057** | `show` に **認可チェックなし**。 注文IDを変えれば他人の注文が見える(IDOR)。 個人情報・取引情報の漏洩。 | 認可 / IDOR |
| **BAD-058** | 在庫・自己購入チェックを `if` の山で書いている。 ポリシーオブジェクトに切り出すべき。 | 凝集度 |
| **BAD-059** | 税計算を Controller に直書き(`book.price * 0.1`)。 Book#price_with_tax があるのに使っていない。 これで税計算は **5箇所目**。 | DRY |
| **BAD-060** | 送料計算を再実装。 閾値が **2000円で250円**、Book#shipping_fee(1000円で300円)と乖離。 | DRY / 仕様乖離 |
| **BAD-061** | `status = "paid"` を直書き。 状態遷移メソッド(BAD-024)があるのに使わない。 状態文字列が散る根本原因。 | Primitive Obsession |
| **BAD-062** | Order の保存と Book の状態更新が **別操作** & **トランザクション無し**。 中間失敗で Order だけ残るデータ不整合。 | トランザクション境界 |
| **BAD-063** | ポイント付与ロジックを再実装。 User#grant_point_for_purchase!(BAD-012)が `1% + 10` なのに対し、 ここでは `0.5%`。 受取時(BAD-069)では `+30` 固定。 **同じポイント仕様が3つ** ある。 | DRY / 仕様乖離 |
| **BAD-064** | 通知作成を直書き。 Order の `after_create`(BAD-029)でも通知を作っているため **二重通知** が出る。 | 副作用の散在 |
| **BAD-065** | メール送信を同期で2発。 SMTP障害で購入処理ごと止まる。 ジョブ化されていない。 | 副作用の制御 / 可用性 |
| **BAD-066** | アクセスログを `Rails.logger.info` でベタ書きし、 **メールアドレスを平文で出力**。 ログレベル分離もなし。 | セキュリティ / 監査 |
| **BAD-067** | `pay` アクションが、 既に `paid` の注文を再度 `paid` にできる。 状態遷移ガードが無い。 二重決済の温床。 | 状態遷移 |
| **BAD-068** | `ship` に **認可チェックなし**。 buyer や第三者でも発送マークが押せる。 | 認可 / IDOR |
| **BAD-069** | 受取時のポイント付与が `+30` 固定。 BAD-012/BAD-063 と合わせて **ポイントロジックが3箇所** に散乱。 | DRY |

### `app/controllers/reviews_controller.rb`

| ID | 何が悪いか | 違反している原則 |
|---|---|---|
| **BAD-070** | 認可も状態チェックも無し。 注文が `received` になっていなくても、 また購入者でなくてもレビューが書ける。 ビジネスルールが守られない。 | 認可 / ビジネスルール |

### `app/helpers/application_helper.rb`

| ID | 何が悪いか | 違反している原則 |
|---|---|---|
| **BAD-071** | "便利関数置き場" としてのヘルパー。 用途で分割すべき。 | SRP |
| **BAD-072** | 価格整形ヘルパー。 Book#display_price(BAD-022)、 View 内の ERB 補間(BAD-080)と **三重実装**。 | DRY |
| **BAD-073** | 税計算ヘルパー。 これで税計算は5箇所目(BAD-020/042/059)。 | DRY |
| **BAD-074** | `status_label` ヘルパー。 Book#status_label(BAD-023)と二重実装。 | DRY |
| **BAD-075** | 認可ロジック `can_edit_book?` が View からも呼べてしまう。 認可は Policy にまとめるべき。 | 認可の散在 |
| **BAD-076** | ヘルパー内で `Notification.where(...).count` と **DB アクセス**。 View 描画中に SQL が飛ぶ。 | レイヤ分離 / パフォーマンス |

### `app/mailers/order_mailer.rb`

| ID | 何が悪いか | 違反している原則 |
|---|---|---|
| **BAD-077** | メイル文面の組み立てが Mailer / View / Order#after_create / OrdersController に散在し、 共通テンプレートが無い。 | DRY |

### Views

| ID | 場所 | 何が悪いか | 違反している原則 |
|---|---|---|---|
| **BAD-078** | `books/index` | 検索フォームを直書き。 partial 化されておらず、 他ページの検索欄と挙動が分かれる温床。 | DRY |
| **BAD-079** | `books/index` | each ブロックで `book.seller.average_rating`(BAD-009) を呼ぶ → **N+1**。 集計クエリ + `includes` で解消。 | パフォーマンス |
| **BAD-080** | `books/index` | ERB 内で **税計算・送料計算を直書き** している。 これで税計算/送料計算は ApplicationController / Helper / Book / OrdersController と合わせて散在の極み。 | DRY |
| **BAD-081** | `books/show` | `display_price`(BAD-022) と `number_to_currency` を同じページで併用 → 表示フォーマットが割れる。 | 一貫性 |
| **BAD-082** | `books/show` | View で `@book.status == "listed"` の **文字列比較**。 status を enum 化していないツケが View に出る。 | Primitive Obsession |
| **BAD-083** | `users/show` | `b.order.buyer.name` で **N+1 連鎖**(book → order → buyer)。 | パフォーマンス |
| **BAD-084** | `orders/index` | `b.order` を毎回引いて N+1。 | パフォーマンス |

### `config/routes.rb`

| ID | 何が悪いか | 違反している原則 |
|---|---|---|
| **BAD-085** | 認証関連を `/signup`, `/login`, `/logout` の手書きルートで定義。 `resources :sessions`, `resources :users` で素直に書ける。 RESTful 設計が崩れる。 | RESTful 設計 |
| **BAD-086** | `books` リソースの `member` に `favorite` / `unfavorite` / `buy` を生やしている。 favorite は別リソース、 buy は orders#create にすべき。 リソース設計の崩壊。 | RESTful 設計 |

### Specs

| ID | 場所 | 何が悪いか | 違反している原則 |
|---|---|---|---|
| **BAD-087** | `spec/models/user_spec.rb` | テスト自体に **モブと巨大 before** のアンチパターンを残してある(各 it から前提が見えづらい)。 「テストにも設計がある」題材。 | テストの設計 |
| **BAD-088** | `spec/models/book_spec.rb` | `Book.search` の "現状挙動" を確認するだけで、 SQL Injection の脆弱性に **気付かない** テスト構造。 攻撃文字列を渡すテストを追加すべき。 | セキュリティ・テスト |
| **BAD-089** | `spec/requests/orders_flow_spec.rb` | 「2つの購入経路で合計金額が違う」ことを **正常系として記録** している(現状追認テスト)。 これはバグ仕様の固定化。 | テストの設計 |

### Seed

| ID | 何が悪いか | 違反している原則 |
|---|---|---|
| **BAD-090** | seed が冪等ではなく `delete_all` してから入れ直す方式。 開発DBの状態を破壊しがち。 | 冪等性 |

---

## 🎓 リファクタリング演習スケジュール(全6回想定)

### Step 1 — Fat Controller を薄くする
**主な対象**: BAD-055, 058, 059, 060, 061, 062, 064, 065, 066

- `OrdersController#create` を15行以内に収める
- Service Object / Form Object / Command パターンの選択
- 副作用(通知・メール・ログ)の責務分離
- **トランザクション境界** をどこに引くか

### Step 2 — Primitive Obsession を Value Object へ
**主な対象**: BAD-017, 020, 021, 022, 032, 042, 043, 059, 060, 072, 073, 080, 081

- 価格・税・送料を `Money` 型に
- 税計算と送料計算を1箇所に集約(5箇所散在を解消)
- View / Helper / Controller の重複を削除

### Step 3 — 状態管理を state machine 化
**主な対象**: BAD-017, 023, 024, 026, 027, 061, 067, 074, 082

- `Book#status` / `Order#status` を enum + state machine 化
- 不正な状態遷移をガード
- View / Controller の文字列比較を排除

### Step 4 — N+1 退治と Query Object
**主な対象**: BAD-006, 007, 009, 025, 033, 047, 048, 049, 056, 076, 079, 083, 084, 088

- `includes` の導入
- `BookSearch` / `UserStatistics` Query Object に切り出し
- SQL Injection の修正(プレースホルダ化)

### Step 5 — 認証・認可の整理
**主な対象**: BAD-008, 038, 040, 044, 045, 046, 050, 051, 057, 068, 070, 075, 085, 086

- Pundit などの Policy 層を導入
- Strong Parameters の全面適用
- ルーティングを RESTful に整理
- アカウント列挙対策(ログイン失敗メッセージ統一)

### Step 6 — 副作用(通知・メール)の分離
**主な対象**: BAD-004, 005, 011, 019, 028, 029, 031, 036, 062, 064, 065, 077

- after_* コールバックを排除し、 明示的な Notifier / Job に置換
- 二重通知バグの修正
- ActiveJob で非同期化

---

## 📚 想定到達点 (After のスケッチ)

```
app/
├── models/
│   ├── book.rb            # 状態は enum、計算ロジックは Money に委譲
│   ├── order.rb           # 状態遷移メソッドのみ
│   ├── user.rb            # 認証と関連定義のみ
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
  - 例: 「BooksController#buy 経由」と「カート確認画面 (OrdersController#create) 経由」で合計金額が違うバグ(BAD-054 vs BAD-060)
  - 例: 注文の URL を `/orders/1`, `/orders/2`, ... と変えると他人の注文が丸見え(BAD-057)
  - 例: 他人の出品ページの `/books/N/edit` を直接叩くと編集できる(BAD-051)

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
