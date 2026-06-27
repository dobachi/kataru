.PHONY: build lint run help

help:
	@echo "make build  - scenario/maps/*.md -> data/maps/*.json へ変換"
	@echo "make lint   - マップ記法を検証"
	@echo "make run    - Godot でゲームを起動"

build:
	python3 tools/kataru.py convert --all

lint:
	python3 tools/kataru.py lint --all

run:
	godot --path .
