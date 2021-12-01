TOOLS_IMAGE := ministryofjustice/cloud-platform-tools:2.0

tools-shell:
	docker pull --platform=linux/amd64 $(TOOLS_IMAGE)
	docker run --platform=linux/amd64 --rm -it \
    -e AWS_PROFILE=$${AWS_PROFILE} \
    -e AUTH0_DOMAIN=$${AUTH0_DOMAIN} \
    -e AUTH0_CLIENT_ID=$${AUTH0_CLIENT_ID} \
    -e AUTH0_CLIENT_SECRET=$${AUTH0_CLIENT_SECRET} \
    -e KOPS_STATE_STORE=$${KOPS_STATE_STORE} \
		-v $$(pwd):/app \
		-v $${HOME}/.aws:/root/.aws \
		-v $${HOME}/.gnupg:/root/.gnupg \
		-v $${HOME}/.docker:/root/.docker \
		-w /app \
		$(TOOLS_IMAGE) bash

# For CP team-members. List all the clusters which currently exist
list-clusters:
	kops get clusters
	@echo
	aws eks list-clusters --region=eu-west-2
