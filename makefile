TOOLS_IMAGE := 754256621582.dkr.ecr.eu-west-2.amazonaws.com/cloud-platform/tools
TOOLS_HOME := /home/toolsuser

tools-shell:
	docker pull $(TOOLS_IMAGE)
	docker run --rm -it \
    -e AWS_PROFILE=$${AWS_PROFILE} \
    -e AUTH0_DOMAIN=$${AUTH0_DOMAIN} \
    -e AUTH0_CLIENT_ID=$${AUTH0_CLIENT_ID} \
    -e AUTH0_CLIENT_SECRET=$${AUTH0_CLIENT_SECRET} \
    -e KOPS_STATE_STORE=$${KOPS_STATE_STORE} \
		-v $${HOME}/.aws:$(TOOLS_HOME)/.aws \
		-v $${HOME}/.gnupg:$(TOOLS_HOME)/.gnupg \
		-v $$(pwd):$(TOOLS_HOME)/infra \
		-w $(TOOLS_HOME)/infra \
		$(TOOLS_IMAGE) bash
