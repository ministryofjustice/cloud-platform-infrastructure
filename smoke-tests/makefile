IMAGE := ministryofjustice/cloud-platform-smoke-tests:1.2
KUBE_CONFIG := ~/.kube/config
AWS_PROFILE := moj-cp # Cloud Platform AWS account

build:
	docker build -t $(IMAGE) .

push:
	docker tag $(IMAGE) $(IMAGE)
	docker push $(IMAGE)

shell:
	docker run --rm -it \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/spec:/app/spec \
		-v $${HOME}/.aws:/app/.aws \
		-e AWS_CONFIG_FILE=/app/.aws/config \
		-e AWS_PROFILE=$(AWS_PROFILE) \
		-e AWS_SHARED_CREDENTIALS_FILE=/app/.aws/credentials \
		-e KUBECONFIG=/app/config \
		$(IMAGE) sh

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
		$(IMAGE) rspec

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
		$(IMAGE) rspec --tag cluster:live-1

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
		$(IMAGE) rspec --tag ~cluster:live-1
