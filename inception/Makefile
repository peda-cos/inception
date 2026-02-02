COMPOSE = docker compose -f srcs/docker-compose.yml
DATA_PATH = /home/login/data

all:
	@mkdir -p $(DATA_PATH)/wordpress
	@mkdir -p $(DATA_PATH)/mariadb
	@mkdir -p $(DATA_PATH)/redis
	@mkdir -p $(DATA_PATH)/portainer
	@echo "Building and starting all services..."
	@$(COMPOSE) up -d --build nginx wordpress mariadb redis ftp adminer static-site portainer
	@echo "Done! WordPress: https://peda-cos.42.fr"

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

.PHONY: all clean fclean re
