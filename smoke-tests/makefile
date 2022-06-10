IMAGE := ministryofjustice/cloud-platform-smoke-tests
VERSION := 1.8
TAGGED_IMAGE := $(IMAGE):$(VERSION)
KUBE_CONFIG := ~/.kube/config
AWS_PROFILE := moj-cp # Cloud Platform AWS account

build: .built-docker-image

.built-docker-image: Dockerfile Gemfile Gemfile.lock makefile
	docker buildx build --platform=linux/amd64 -t $(IMAGE) .
	touch .built-docker-image

tag: .built-docker-image
	docker tag $(IMAGE) $(TAGGED_IMAGE)
	docker tag $(IMAGE) $(IMAGE):latest

push:
	make tag
	docker push $(TAGGED_IMAGE)
	docker push $(IMAGE):latest

shell:
	docker run --platform=linux/amd64 --rm -it \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/spec:/app/spec \
		-v $${HOME}/.aws:/app/.aws \
		-e AWS_CONFIG_FILE=/app/.aws/config \
		-e AWS_PROFILE=$(AWS_PROFILE) \
		-e AWS_SHARED_CREDENTIALS_FILE=/app/.aws/credentials \
		-e KUBECONFIG=/app/config \
		$(TAGGED_IMAGE) sh

# Runs all tests, against whichever kops cluster your .kube/config points to
test:
	docker run --platform=linux/amd64 --rm \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/spec:/app/spec \
		-v $${HOME}/.aws:/app/.aws \
		-e AWS_CONFIG_FILE=/app/.aws/config \
		-e AWS_PROFILE=$(AWS_PROFILE) \
		-e AWS_SHARED_CREDENTIALS_FILE=/app/.aws/credentials \
		-e KUBECONFIG=/app/config \
		$(TAGGED_IMAGE) rspec --tag ~eks-manager

# Only run tests tagged with "live-1": true and NOT tagged with "eks-manager": true
test-live-1:
	docker run --platform=linux/amd64 --rm \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/spec:/app/spec \
		-v $${HOME}/.aws:/app/.aws \
		-e AWS_CONFIG_FILE=/app/.aws/config \
		-e AWS_PROFILE=$(AWS_PROFILE) \
		-e AWS_SHARED_CREDENTIALS_FILE=/app/.aws/credentials \
		-e KUBECONFIG=/app/config \
		$(TAGGED_IMAGE) rspec --tag live-1 --tag ~eks-manager

# Only run tests NOT tagged with "live-1": true and "eks-manager": true
test-non-live-1:
	docker run --platform=linux/amd64 --rm \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/spec:/app/spec \
		-v $${HOME}/.aws:/app/.aws \
		-e AWS_CONFIG_FILE=/app/.aws/config \
		-e AWS_PROFILE=$(AWS_PROFILE) \
		-e AWS_SHARED_CREDENTIALS_FILE=/app/.aws/credentials \
		-e KUBECONFIG=/app/config \
		$(TAGGED_IMAGE) rspec --tag ~live-1 --tag ~eks-manager

# Only run tests NOT tagged with "live-1": true and kops: true
test-eks:
	docker run --platform=linux/amd64 --rm \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/spec:/app/spec \
		-v $${HOME}/.aws:/app/.aws \
		-e AWS_CONFIG_FILE=/app/.aws/config \
		-e AWS_PROFILE=$(AWS_PROFILE) \
		-e AWS_SHARED_CREDENTIALS_FILE=/app/.aws/credentials \
		-e KUBECONFIG=/app/config \
		$(TAGGED_IMAGE) rspec --tag ~live-1 --tag ~kops

# Only run tests tagged with speed: fast
test-fast:
	docker run --platform=linux/amd64 --rm \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/spec:/app/spec \
		-v $${HOME}/.aws:/app/.aws \
		-e AWS_CONFIG_FILE=/app/.aws/config \
		-e AWS_PROFILE=$(AWS_PROFILE) \
		-e AWS_SHARED_CREDENTIALS_FILE=/app/.aws/credentials \
		-e KUBECONFIG=/app/config \
		$(TAGGED_IMAGE) rspec --tag speed:fast

# Only run tests tagged with speed: fast and NOT tagged with "live-1": true and "eks-manager": true
test-fast-non-live-1:
	docker run --platform=linux/amd64 --rm \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/spec:/app/spec \
		-v $${HOME}/.aws:/app/.aws \
		-e AWS_CONFIG_FILE=/app/.aws/config \
		-e AWS_PROFILE=$(AWS_PROFILE) \
		-e AWS_SHARED_CREDENTIALS_FILE=/app/.aws/credentials \
		-e KUBECONFIG=/app/config \
		$(TAGGED_IMAGE) rspec --tag speed:fast --tag ~live-1 --tag ~eks-manager
