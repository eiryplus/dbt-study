# dbt learning environment

Python 3.13 + Poetry + PostgreSQL を Docker 上で動かす dbt 学習用環境です。
登録されているデータは全てダミーで、データベースのアカウント情報もコンテナでしか利用しないものです。
仮に本番運用で本構成を参考にする場合、データ・アカウント情報の取り扱いは十分に注意してください。

## 構成

- `dbt` コンテナ: Python 3.13 / Poetry で `dbt-core` + `dbt-postgres` を管理
- `postgres` コンテナ: パイプライン用の PostgreSQL 16
- コーディング規約: PEP8 ベース、1行の上限は 110 文字（`.flake8` / `pyproject.toml` の black・isort 設定）

## サンプル dbt プロジェクトのレイヤー構成

`dbt_project/models` は以下の5層構成になっています。

```
lake         : raw ソース（seed）を1:1で取り込むだけの層（カラム名・型の統一のみ）
staging      : 表記ゆれの吸収・トリム・異常値除外などのクレンジング層
intermediate : 複数モデルの結合・集計を行うビジネスロジック層
dwh          : 再利用可能なディメンション/ファクトテーブル（conformed）
mart         : 特定用途（顧客サマリー・月次売上など）向けの最終集計層
```

各層は PostgreSQL 上で別スキーマ（`raw` / `lake` / `staging` / `intermediate` / `dwh` / `mart`）に
マテリアライズされ、`psql` から `\dn` や `\dt <schema>.*` で確認できます。

題材は「顧客・注文・支払い」の簡易ECサンプルデータです（`dbt_project/seeds/*.csv`）。

## PII マスキング

[dbt_privacy](https://github.com/pvcy/dbt-privacy) パッケージ（`dbt_project/packages.yml`）を導入し、
`stg_customers` モデルで氏名（`first_name` / `last_name`）を `dbt_privacy.mask()` マクロによりマスキングしています。
staging 層でマスキングすることで、下流の `intermediate` / `dwh` / `mart` にも自動的に反映されます。

## メタデータ管理（dbt-osmosis）

[dbt-osmosis](https://github.com/z3z1ma/dbt-osmosis) を導入し、schema YAML（`_<層名>__models.yml` /
`_seeds__models.yml`）とデータベースの実スキーマを同期させています。カラムの追加・削除やデータ型を
手動でYAMLに反映する必要がなくなり、既存の `description` / `tests` は保持したまま不足しているカラム定義
（`data_type` を含む）が自動補完されます。YAMLの出力先パターンは `dbt_project/dbt_project.yml` の
`vars.dbt_osmosis_default_path` で指定しており、既存の層ごとのファイル構成（`_lake__models.yml` など）を
維持するようにしています。

```bash
# 差分チェック（CI等で利用。YAMLとDBスキーマに差分があれば非ゼロで終了）
make osmosis-check

# 差分を実際にYAMLへ反映
make osmosis-refactor
```

なお、PII情報であるカラムをメタデータに自動で識別・付与し下流へ伝搬する仕組みは今回のスコープ外です。

## セットアップ

```bash
cp .env.example .env   # 必要に応じて認証情報を編集
cp .mcp.json.example .mcp.json   # 必要に応じて情報を編集

docker compose build
docker compose up -d
```

## dbt コマンドの実行

`dbt` コンテナは起動したままになるので、`exec` でコマンドを実行します。

```bash
# パッケージインストール（dbt_privacy など packages.yml に定義したパッケージを取得）
# ※ docker compose build 時点で Dockerfile 内で自動実行され、専用の named volume に保存されるため通常は不要
docker compose exec dbt poetry run dbt deps --project-dir dbt_project

# 接続確認
docker compose exec dbt poetry run dbt debug --project-dir dbt_project

# seed データ投入
docker compose exec dbt poetry run dbt seed --project-dir dbt_project

# モデル実行（lake -> staging -> intermediate -> dwh -> mart の順に依存解決される）
docker compose exec dbt poetry run dbt run --project-dir dbt_project

# テスト実行
docker compose exec dbt poetry run dbt test --project-dir dbt_project

# ドキュメント生成 + 閲覧（http://localhost:8080、あらかじめ 8080 番ポートを公開済み）
docker compose exec dbt poetry run dbt docs generate --project-dir dbt_project
docker compose exec dbt poetry run dbt docs serve --project-dir dbt_project --port 8080 --host 0.0.0.0
```

## Lint / フォーマット（PEP8, 1行110文字）

dbt本体はDockerコンテナ内で実行しますが、Lint・フォーマットはローカルPC上で実行します。

```bash
python3.13 -m venv .venv
. .venv/bin/activate
poetry install

poetry run flake8 .
poetry run black --check .
poetry run isort --check .
```

## PostgreSQL への直接接続

```bash
docker compose exec postgres psql -U dbt -d dbt_learning
```

```sql
\dn                      -- スキーマ一覧
select * from mart.mart_customer_summary;
select * from mart.mart_monthly_revenue;
```

## 後片付け

```bash
docker compose down        # コンテナ停止
docker compose down -v     # + PostgreSQL のデータも削除
```

## PostgreSQL　MCP Server

```
python3.13 -m venv .venv
. .venv/bin/activate
poetry install
uv pip install postgres-mcp
```
