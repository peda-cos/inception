COMPOSE = docker compose -f srcs/docker-compose.yml --env-file srcs/.env
DATA_PATH = /home/peda-cos/data
SECRETS_PATH = /home/peda-cos/secrets

all: secrets
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p $(DATA_PATH)/mariadb
	@mkdir -p $(DATA_PATH)/redis
	@mkdir -p $(DATA_PATH)/portainer
	@echo "Building and starting all services..."
	@$(COMPOSE) up -d --build nginx wordpress mariadb redis ftp adminer static-site portainer
	@echo "Done! WordPress: https://peda-cos.42.fr"

secrets:
	@mkdir -p $(SECRETS_PATH)
	@if [ ! -f $(SECRETS_PATH)/db_password.txt ]; then \
		openssl rand -base64 48 | tr -d '/+=' | head -c 32 > $(SECRETS_PATH)/db_password.txt; \
		echo "[secrets] Generated db_password.txt"; \
	fi
	@if [ ! -f $(SECRETS_PATH)/db_root_password.txt ]; then \
		openssl rand -base64 48 | tr -d '/+=' | head -c 32 > $(SECRETS_PATH)/db_root_password.txt; \
		echo "[secrets] Generated db_root_password.txt"; \
	fi
	@if [ ! -f $(SECRETS_PATH)/ftp_password.txt ]; then \
		openssl rand -base64 48 | tr -d '/+=' | head -c 32 > $(SECRETS_PATH)/ftp_password.txt; \
		echo "[secrets] Generated ftp_password.txt"; \
	fi
	@if [ ! -f $(SECRETS_PATH)/credentials.txt ]; then \
		printf 'WORDPRESS_ADMIN_PASSWORD=%s\nWORDPRESS_USER_PASSWORD=%s\n' \
			"$$(openssl rand -base64 48 | tr -d '/+=' | head -c 32)" \
			"$$(openssl rand -base64 48 | tr -d '/+=' | head -c 32)" \
			> $(SECRETS_PATH)/credentials.txt; \
		echo "[secrets] Generated credentials.txt"; \
	fi

clean:
	@$(COMPOSE) down
	@echo "Cleaned."

fclean: clean
	@$(COMPOSE) down -v
	@docker stop $$(docker ps -aq) 2>/dev/null || true
	@docker rm -f $$(docker ps -aq) 2>/dev/null || true
	@docker system prune -a --volumes -f
	@sudo rm -rf $(DATA_PATH)
	@docker images
	@docker ps -a
	@echo "Fully cleaned."

re: fclean all

.PHONY: all secrets clean fclean re
