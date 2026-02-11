.PHONY: help release check-git test-all lint fix-commit

CURRENT_VERSION := $(shell python3 -c "print(next(line.split(':')[1].strip() for line in open('pubspec.yaml') if line.startswith('version:')))")

help:
	@echo "📘 Bavard Migration Release Manager"
	@echo "ℹ️  Current Version: $(CURRENT_VERSION)"
	@echo "Usage: make release v=X.Y.Z"
	@echo "Example: make release v=0.0.2"
	@echo "--------------------------------------"
	@echo "🛠️  Development"
	@echo "  make tidy          : Format code, analyze, and commit fixes (style: lint and formatting updates)"
	@echo "--------------------------------------"
	@echo "🧪 Testing"
	@echo "  make test-all      : Run Unit Tests"

check-git:
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo "❌ Error: Working directory is dirty. Please commit or stash your changes first."; \
		exit 1; \
	fi

tidy:
	@echo "🎨 Formatting code..."
	@dart format .
	@echo "🔍 Analyzing code..."
	@dart analyze .
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo "📦 Committing formatting changes..."; \
		git add .;		
		git commit -m "style: lint and formatting updates"; \
		echo "✅ Code formatted and committed."; \
	else \
		echo "✨ No formatting changes needed."; \
	fi

test-all:
	@echo "🧪 Running Unit Tests..."
	dart test
	@echo "✅ Unit Tests Passed"
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
	git commit -m "chore(migration): release v$(v)"

	@echo "🏷️ Creating Tag migration-v$(v)..."
	git tag migration-v$(v)

	@echo "🚀 Pushing to origin (branch + tags)..."
	git push origin HEAD
	git push origin migration-v$(v)

	@echo "✅ Done! Version $(v) released and pushed."
	@echo "💡 Optional next step: 'dart pub publish'"
