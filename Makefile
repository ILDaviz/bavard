.PHONY: help release check-git gen-docs

CURRENT_VERSION := $(shell python3 -c "print(next(line.split(':')[1].strip() for line in open('pubspec.yaml') if line.startswith('version:')))")

help:
	@echo "📘 Bravard ORM Release Manager"
	@echo "ℹ️  Current Version: $(CURRENT_VERSION)"
	@echo "Usage: make release v=X.Y.Z"
	@echo "Example: make release v=0.0.2"

check-git:
	@if [ -n "$$(git status --porcelain)" ]; then \
		echo "❌ Error: Working directory is dirty. Please commit or stash your changes first."; \
		exit 1; \
	fi

gen-docs:
	@echo "📝 Generating LLM documentation..."
	cd docs && aicontextator --tree -o ../llm-doc.txt --ext .md
	aicontextator --tree -o llm-code.txt --ext .dart --ext .yaml

release: check-git
	@if [ -z "$(v)" ]; then \
		echo "❌ Error: Please specify the version. Example: make release v=0.0.2"; \
		exit 1; \
	fi

	@echo "🚀 Starting release process..."
	@echo "   Current Version: $(CURRENT_VERSION)"
	@echo "   Target Version:  $(v)"
	@echo "--------------------------------------"

	@echo "📝 Generating LLM Context..."
	cd docs && aicontextator --tree -o ../llm-doc.txt --ext .md
	aicontextator --tree -o llm-code.txt --ext .dart --ext .yaml

	@echo "🔄 Updating version in pubspec.yaml..."
	@python3 -c "import sys; f='pubspec.yaml'; lines=open(f).readlines(); open(f,'w').writelines(['version: '+sys.argv[1]+'\n' if line.startswith('version:') else line for line in lines])" $(v)

	@echo "📦 Committing pubspec.yaml and LLM docs..."
	git add pubspec.yaml llm-code.txt llm-doc.txt
	git commit -m "chore: bump version to $(v) and update llm docs"

	@echo "🏷️ Creating Tag v$(v)..."
	git tag v$(v)

	@echo "🚀 Pushing to origin (branch + tags)..."
	git push origin HEAD
	git push origin v$(v)

	@echo "✅ Done! Version $(v) released and pushed."
	@echo "💡 Optional next step: 'dart pub publish'"