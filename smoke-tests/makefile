IMAGE := ministryofjustice/cloud-platform-smoke-tests
VERSION := 1.7
TAGGED_IMAGE := $(IMAGE):$(VERSION)
KUBE_CONFIG := ~/.kube/config
AWS_PROFILE := moj-cp # Cloud Platform AWS account

build: .built-docker-image

.built-docker-image: Dockerfile Gemfile Gemfile.lock makefile
	docker build -t $(IMAGE) .
	touch .built-docker-image

tag: .built-docker-image
	docker tag $(IMAGE) $(TAGGED_IMAGE)
	docker tag $(IMAGE) $(IMAGE):latest

push:
	make tag
	docker push $(TAGGED_IMAGE)
	docker push $(IMAGE):latest

shell:
	docker run --rm -it \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/spec:/app/spec \
		-v $${HOME}/.aws:/app/.aws \
		-e AWS_CONFIG_FILE=/app/.aws/config \
		-e AWS_PROFILE=$(AWS_PROFILE) \
		-e AWS_SHARED_CREDENTIALS_FILE=/app/.aws/credentials \
		-e KUBECONFIG=/app/config \
		$(TAGGED_IMAGE) sh

# Runs all tests, against whichever cluster your .kube/config points to
test:
	docker run --rm \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/spec:/app/spec \
		-v $${HOME}/.aws:/app/.aws \
		-e AWS_CONFIG_FILE=/app/.aws/config \
		-e AWS_PROFILE=$(AWS_PROFILE) \
		-e AWS_SHARED_CREDENTIALS_FILE=/app/.aws/credentials \
		-e KUBECONFIG=/app/config \
		$(TAGGED_IMAGE) rspec

# Only run tests tagged with cluster: live-1
test-live-1:
	docker run --rm \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/spec:/app/spec \
		-v $${HOME}/.aws:/app/.aws \
		-e AWS_CONFIG_FILE=/app/.aws/config \
		-e AWS_PROFILE=$(AWS_PROFILE) \
		-e AWS_SHARED_CREDENTIALS_FILE=/app/.aws/credentials \
		-e KUBECONFIG=/app/config \
		$(TAGGED_IMAGE) rspec --tag cluster:live-1

# Only run tests NOT tagged with cluster: live-1
test-non-live-1:
	docker run --rm \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/spec:/app/spec \
		-v $${HOME}/.aws:/app/.aws \
		-e AWS_CONFIG_FILE=/app/.aws/config \
		-e AWS_PROFILE=$(AWS_PROFILE) \
		-e AWS_SHARED_CREDENTIALS_FILE=/app/.aws/credentials \
		-e KUBECONFIG=/app/config \
		$(TAGGED_IMAGE) rspec --tag ~cluster:live-1

# Only run tests tagged with speed: fast
test-fast:
	docker run --rm \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/spec:/app/spec \
		-v $${HOME}/.aws:/app/.aws \
		-e AWS_CONFIG_FILE=/app/.aws/config \
		-e AWS_PROFILE=$(AWS_PROFILE) \
		-e AWS_SHARED_CREDENTIALS_FILE=/app/.aws/credentials \
		-e KUBECONFIG=/app/config \
		$(TAGGED_IMAGE) rspec --tag speed:fast

