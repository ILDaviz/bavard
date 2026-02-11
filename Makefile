.PHONY: test format

test:
	$(MAKE) -C packages/bavard test-all

format:
	$(MAKE) -C packages/bavard tidy
