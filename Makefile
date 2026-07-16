PROJECT_DIR := dbt_project
DBT := docker compose exec dbt poetry run dbt
DBT_OSMOSIS := docker compose exec dbt poetry run dbt-osmosis
# dbt-osmosis はプロジェクトルートを解決する際に相対パスを正規化しないため、
# コンテナ内の絶対パスを渡す必要がある（相対パスだと出力先ディレクトリが二重になる）
OSMOSIS_PROJECT_DIR := /usr/app/$(PROJECT_DIR)
EDR := docker compose exec dbt poetry run edr

.PHONY: deps debug seed run test docs-generate docs-serve lint format osmosis-check osmosis-refactor elementary-report

deps: ## パッケージインストール
	$(DBT) deps --project-dir $(PROJECT_DIR)

debug: ## 接続確認
	$(DBT) debug --project-dir $(PROJECT_DIR)

seed: ## seed データ投入
	$(DBT) seed --project-dir $(PROJECT_DIR)

run: ## モデル実行（lake -> staging -> intermediate -> dwh -> mart の順に依存解決される）
	$(DBT) run --project-dir $(PROJECT_DIR)

test: ## テスト実行
	$(DBT) test --project-dir $(PROJECT_DIR)

docs-generate: ## ドキュメント生成
	$(DBT) docs generate --project-dir $(PROJECT_DIR)

docs-serve: ## ドキュメント閲覧（http://localhost:8080）
	$(DBT) docs serve --project-dir $(PROJECT_DIR) --port 8080 --host 0.0.0.0

lint: ## Lintチェック（ローカルPCで実行）
	poetry run flake8 .
	poetry run black --check .
	poetry run isort --check .

format: ## フォーマット（ローカルPCで実行）
	poetry run black .
	poetry run isort .

osmosis-check: ## メタデータYAMLとDBスキーマの差分チェック（変更が必要なら非ゼロで終了）
	$(DBT_OSMOSIS) yaml refactor --project-dir $(OSMOSIS_PROJECT_DIR) --dry-run --check --auto-apply

osmosis-refactor: ## メタデータYAML（カラム定義・description継承）をDBスキーマに同期して自動整備
	$(DBT_OSMOSIS) yaml refactor --project-dir $(OSMOSIS_PROJECT_DIR) --auto-apply

elementary-report: ## テスト結果をelementaryでHTMLレポート出力（事前に make test の実行が必要。出力先: dbt_project/elementary_report.html）
	$(DBT) run --project-dir $(PROJECT_DIR) --select elementary
	$(EDR) monitor report --project-dir $(PROJECT_DIR) --profiles-dir $(PROJECT_DIR) --file-path $(PROJECT_DIR)/elementary_report.html
