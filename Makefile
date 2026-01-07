.PHONY: help release check-git test-all

CURRENT_VERSION := $(shell python3 -c "print(next(line.split(':')[1].strip() for line in open('pubspec.yaml') if line.startswith('version:')))")

help:
	@echo "📘 Bravard ORM Release Manager"
	@echo "ℹ️  Current Version: $(CURRENT_VERSION)"
	@echo "Usage: make release v=X.Y.Z"
	@echo "Example: make release v=0.0.2"
	@echo "--------------------------------------"
	@echo "🧪 Testing"
	@echo "  make test-all      : Run Unit Tests + SQLite (Docker) + Postgres (Docker One-shot)"

check-git:
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo "❌ Error: Working directory is dirty. Please commit or stash your changes first."; \
		exit 1; \
	fi

test-all:
	@echo "🧪 Running Unit Tests..."
	dart test
	@echo "✅ Unit Tests Passed"
	@echo "--------------------------------------"
	@echo "🧪 Running Builder Usage Example Tests..."
	cd example/builder_usage && dart pub get && dart run build_runner build --delete-conflicting-outputs && dart test
	@echo "✅ Builder Usage Tests Passed"
	@echo "--------------------------------------"
	@echo "🐳 Running SQLite Integration Tests..."
	docker build -f example/sqlite-docker/Dockerfile -t bavard-sqlite-test . && docker run --rm bavard-sqlite-test
	@echo "✅ SQLite Tests Passed"
	@echo "--------------------------------------"
	@echo "🐳 Running PostgreSQL Integration Tests (One-shot)..."
	docker compose -f example/postgresql-docker/docker-compose.yaml up --build --abort-on-container-exit --exit-code-from app
	@echo "🧹 Cleaning up Postgres containers and volumes..."
	docker compose -f example/postgresql-docker/docker-compose.yaml down -v
	@echo "✅ PostgreSQL Tests Passed"
	@echo "--------------------------------------"
	@echo "🎉 ALL TESTS PASSED SUCCESSFULLY! 🎉"

release: check-git
	@if [ -z "$(v)" ]; then \
		echo "❌ Error: Please specify the version. Example: make release v=0.0.2"; \
		exit 1; \
	fi

	@echo "🚀 Starting release process..."
	@echo "   Current Version: $(CURRENT_VERSION)"
	@echo "   Target Version:  $(v)"
	@echo "--------------------------------------"

	@echo "🔄 Updating version in pubspec.yaml..."
	@python3 -c "import sys; f='pubspec.yaml'; lines=open(f).readlines(); open(f,'w').writelines(['version: '+sys.argv[1]+'\n' if line.startswith('version:') else line for line in lines])" $(v)

	@echo "📝 Updating CHANGELOG.md..."
	@python3 -c "import sys, datetime; v=sys.argv[1]; d=datetime.date.today().strftime('%Y-%m-%d'); f='CHANGELOG.md'; c=open(f).read(); open(f,'w').write(c.replace('## [Unreleased]', '## [Unreleased]\n\n## ['+v+'] - '+d))" $(v)

	@echo "📦 Committing release files..."
	git add pubspec.yaml CHANGELOG.md
	git commit -m "chore: release v$(v)"

	@echo "🏷️ Creating Tag v$(v)..."
	git tag v$(v)

	@echo "🚀 Pushing to origin (branch + tags)..."
	git push origin HEAD
	git push origin v$(v)

	@echo "✅ Done! Version $(v) released and pushed."
	@echo "💡 Optional next step: 'dart pub publish'"