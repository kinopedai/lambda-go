.PHONY: build clean deploy

build:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags="-s -w" -o bootstrap main.go
	zip lambda-deployment-package.zip bootstrap

clean:
	rm -f bootstrap lambda-deployment-package.zip

deploy: build
	aws lambda update-function-code \
		--function-name char-counter-lambda \
		--zip-file fileb://lambda-deployment-package.zip