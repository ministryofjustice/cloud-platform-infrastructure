TOOLS_IMAGE := 754256621582.dkr.ecr.eu-west-2.amazonaws.com/cloud-platform/tools

# The AWS_SHARED_CREDENTIALS_FILE variable is only needed if you have
# the .aws directory mounted somewhere other than /root/.aws I'm just
# leaving it in place for clarity.
tools-shell:
	docker run --rm -it \
    -e AWS_PROFILE=$${AWS_PROFILE} \
    -e AUTH0_DOMAIN=$${AUTH0_DOMAIN} \
    -e AUTH0_CLIENT_ID=$${AUTH0_CLIENT_ID} \
    -e AUTH0_CLIENT_SECRET=$${AUTH0_CLIENT_SECRET} \
    -e KOPS_STATE_STORE=$${KOPS_STATE_STORE} \
		-v $$(pwd):/app \
		-v $${HOME}/.aws:/root/.aws \
		-e AWS_SHARED_CREDENTIALS_FILE=/root/.aws/credentials \
		-v $${HOME}/.gnupg:/root/.gnupg \
		-w /app \
		$(TOOLS_IMAGE) bash
