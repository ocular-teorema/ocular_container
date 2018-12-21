# Ocular Container

### Установка Docker

Устанавливаем Docker по этому мануалу: https://docs.docker.com/install/linux/docker-ce/ubuntu
Устанавливаем Docker Compose по этому мануалу: https://docs.docker.com/compose/install/#install-compose

### Подготовка окружения

 * Выполняем `docker login docker.ddgcorp.ru` по Deploy Token;
 * Создаём директорию `ocular`;
 * В ней размещаем `docker-compose.yml` из данного репозитория;
 * Выполняем `docker-compose up -d`;
 * Выполняем `docker-compose exec ocular docker_createsuperuser`.