PROJECT_DIR := dbt_project
DBT := docker compose exec dbt poetry run dbt

.PHONY: deps debug seed run test docs-generate docs-serve

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
