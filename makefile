# Ent enabled features | Ent 启用的官方特性
ENT_FEATURE=sql/execquery,intercept

MYSQL_DNS ?= mysql://root:123456@localhost:3306
DB_NAME ?= gbill

.PHONY: help
help: # Show help | 显示帮助
	@grep -E '^[a-zA-Z0-9 -]+:.*#'  Makefile | sort | while read -r l; do printf "\033[1;32m$$(echo $$l | cut -f 1 -d':')\033[00m:$$(echo $$l | cut -f 2- -d'#')\n"; done

.PHONY: gen-schame
gen-schame: # Describe schema | 获取Schema的描述
	go run -mod=mod entgo.io/ent/cmd/ent describe ./ent/schema

.PHONY: ent
ent: # New Ent codes | 新建 Ent 的模块
	go run -mod=mod entgo.io/ent/cmd/ent new ${model}
	@echo "Generate Ent files successfully"

.PHONY: gen-ent
gen-ent: # Generate Ent codes | 生成 Ent 的代码
	go run -mod=mod entgo.io/ent/cmd/ent generate --template glob="./template/ent/*.tmpl" ./ent/schema --feature $(ENT_FEATURE)
	@echo "Generate Ent files successfully"

.PHONY: gen-migrate
gen-migrate: gen-ent # Generate migration diff mysql | 迁移文件
	atlas migrate diff migration_name \
		--dir "file://sql" \
		--to "ent://ent/schema" \
		--dev-url "docker://mysql/8/ent"

.PHONY: apply-migrate
apply-migrate: gen-migrate  # Apply migration | 执行迁移文件
	atlas migrate apply \
		--dir "file://sql" \
		--url $(MYSQL_DNS)/$(DB_NAME)
	make migrate-status

.PHONY: migrate-status
migrate-status:  # Apply migration status | 执行迁移文件状态
		atlas migrate status \
			--dir "file://sql" \
			--url $(MYSQL_DNS)/$(DB_NAME)
