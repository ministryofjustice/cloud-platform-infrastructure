TOOLS_IMAGE := tools-ruby # TODO: replace with full ECR image reference

tools-shell:
	docker run --rm -it \
    -e AWS_PROFILE=$${AWS_PROFILE} \
    -e AUTH0_DOMAIN=$${AUTH0_DOMAIN} \
    -e AUTH0_CLIENT_ID=$${AUTH0_CLIENT_ID} \
    -e AUTH0_CLIENT_SECRET=$${AUTH0_CLIENT_SECRET} \
    -e KOPS_STATE_STORE=$${KOPS_STATE_STORE} \
		-v $$(pwd):/app \
		-v $${HOME}/.aws:/app/.aws \
		-e AWS_SHARED_CREDENTIALS_FILE=/app/.aws/credentials \
		-w /app \
		$(TOOLS_IMAGE) bash
