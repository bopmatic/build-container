.PHONY: build
build: main.go go.mod pb/stub.proto
	docker build --force-rm -t bopmatic/build .

.PHONY: publish
publish:
	docker push bopmatic/build
