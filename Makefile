.PHONY: build
build:
	docker build --force-rm -t bopmatic/build .

.PHONY: publish
publish:
	docker push bopmatic/build
