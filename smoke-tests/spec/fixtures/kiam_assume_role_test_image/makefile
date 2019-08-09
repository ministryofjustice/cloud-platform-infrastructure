IMAGE := ministryofjustice/cloud-platform-integration-test-images:1.0

build:
	docker build -t $(IMAGE) .

push:
	docker tag $(IMAGE) $(IMAGE)
	docker push $(IMAGE)

shell:
	docker run --rm -it \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/bin:/app/bin \
		-e KUBERNETES_CLUSTER=$${KUBERNETES_CLUSTER} \
		-e ACCOUNT_ID=$${ACCOUNT_ID} \
		-e ROLE_NAME=$${ROLE_NAME} \
	    -e AWS_REGION=$${AWS_REGION} \
	$(IMAGE) sh

# Runs all tests, against whichever cluster your .kube/config points to
test:
	docker run --rm \
		-v $(KUBE_CONFIG):/app/config \
		-v $${PWD}/bin:/app/bin \
		-e KUBECONFIG=/app/config \
	$(IMAGE) rspec

# # Only run tests tagged with cluster: live-1
# test-live-1:
# 	docker run --rm \
# 		-v $(KUBE_CONFIG):/app/config \
# 		-v $${PWD}/spec:/app/spec \
# 		-e KUBECONFIG=/app/config \
# 		$(IMAGE) rspec --tag cluster:live-1

# # Only run tests NOT tagged with cluster: live-1
# test-non-live-1:
# 	docker run --rm \
# 		-v $(KUBE_CONFIG):/app/config \
# 		-v $${PWD}/spec:/app/spec \
# 		-e KUBECONFIG=/app/config \
# 		$(IMAGE) rspec --tag ~cluster:live-1
