VERSION=0.10
PREFIX=ministryofjustice/cloud-platform-tests
TAG=$(VERSION)

all: build push

build:
	@echo "Building image:"
	docker buildx build --platform=linux/amd64 --network host -t $(PREFIX):$(TAG) .

push:
	@echo "Pushing image:"
	docker push $(PREFIX):$(TAG)

test:
	@echo "Running container:"
	docker run --platform=linux/amd64 -it --rm \
		-v $(KUBE_CONFIG):/tests/config \
		-v $(HOME)/.aws:/tests/.aws \
		-e AWS_CONFIG_FILE=/tests/.aws/config \
		-e AWS_PROFILE=$(AWS_PROFILE) \
		-e AWS_SHARED_CREDENTIALS_FILE=/tests/.aws/credentials \
		-e KUBECONFIG=/tests/config \
		$(PREFIX):$(TAG) sh
