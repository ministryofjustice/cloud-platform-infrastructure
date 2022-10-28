TAG := 2.2.6
TOOLS_IMAGE := ministryofjustice/cloud-platform-tools
TEST_IMAGE := ministryofjustice/cloud-platform-infrastructure

tools-shell:
	docker pull --platform=linux/amd64 $(TOOLS_IMAGE):$(TAG)
	docker run --platform=linux/amd64 --rm -it \
		-v $$(pwd):/app \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-w /app \
		$(TOOLS_IMAGE):$(TAG) bash

# For CP team-members. List all the clusters which currently exist
list-clusters:
	kops get clusters
	@echo
	aws eks list-clusters --region=eu-west-2

run-tests:
	docker pull --platform=linux/amd64 $(TEST_IMAGE):$(TAG)
	docker run --platform=linux/amd64 --rm -it \
    -e AWS_PROFILE=$${AWS_PROFILE} \
		-v $$(pwd):/app \
		-v $${HOME}/.aws:/root/.aws \
		-v $${HOME}/.kube:/root/.kube \
		-v $${HOME}/.gnupg:/root/.gnupg \
		-v $${HOME}/.docker:/root/.docker \
		-w /app \
		$(TEST_IMAGE):$(TAG) bash -c "cd test && ginkgo -v . -args -ginkgo.randomizeAllSpecs -ginkgo.progress -ginkgo.noisySkippings -test.v -ginkgo.slowSpecThreshold=120"

