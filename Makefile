confs := $(shell find services-available -type f | sed 's/^/\-f /')

FILE_SET :=  "SETTINGS.env"
FILE_NETWORK := "network.yaml"
MESSAGE_ERROR := "Please, rename SETTINGS.env.template to SETTINGS.env and fill up their fields accordingly"
MESSAGE_SUCCESS := "All set!"

test-settings:
ifeq (,$(wildcard ./SETTINGS.env))
	$(error $(MESSAGE_ERROR))
endif

up: test-settings
	@docker compose --env-file $(FILE_SET) -f $(FILE_NETWORK) $(confs) up -d
	@echo $(MESSAGE_SUCCESS)

down: test-settings
	@docker compose --env-file $(FILE_SET) -f $(FILE_NETWORK) $(confs) down -v