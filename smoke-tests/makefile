IMAGE := ministryofjustice/cloud-platform-smoke-tests:1.0
KUBE_CONFIG := ~/.kube/config

build:
	docker build -t $(IMAGE) .

push:
	docker tag $(IMAGE) $(IMAGE)
	docker push $(IMAGE)

shell:
	docker run --rm -it \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/spec:/app/spec \
		-e KUBECONFIG=/app/config
	$(IMAGE) sh

# Runs all tests, against whichever cluster your .kube/config points to
test:
	docker run --rm \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/spec:/app/spec \
		-e KUBECONFIG=/app/config \
	$(IMAGE) rspec

# Only run tests tagged with cluster: live-1
test-live-1:
	docker run --rm \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/spec:/app/spec \
		-e KUBECONFIG=/app/config \
		$(IMAGE) rspec --tag cluster:live-1

# Only run tests NOT tagged with cluster: live-1
test-non-live-1:
	docker run --rm \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/spec:/app/spec \
		-e KUBECONFIG=/app/config \
		$(IMAGE) rspec --tag ~cluster:live-1
