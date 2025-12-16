#!/usr/bin/env bash

# Цвета для вопросов
COLOR_ASK=$'\e[1;33m'   # ярко-жёлтый
COLOR_OK=$'\e[1;32m'    # зелёный
COLOR_RESET=$'\e[0m'

# Скрипт установки backend / frontend / backend+frontend на Ubuntu
# Включает: nginx + certbot(HTTPS) + (опционально) pm2 + настройка SSH для GitHub Actions
#
# Важно:
# - Скрипт выполняется НА СЕРВЕРЕ, поэтому .github/workflows/deploy.yml на ваш ПК он "положить" не может.
#   Он создаёт файл /tmp/deploy.yml и печатает команду scp, которой вы заберёте его себе локально.

set -euo pipefail

### ===== Общие функции =====

create_ssh_key() {
  echo ">>> Проверка SSH ключа (для git clone по SSH с сервера)..."
  mkdir -p "$HOME/.ssh"

  if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
    echo "SSH-ключ уже существует: $HOME/.ssh/id_ed25519.pub"
  else
    echo "SSH-ключ не найден, создаю новый ed25519..."
    ssh-keygen -t ed25519 -C "$USER@$(hostname)" -N "" -f "$HOME/.ssh/id_ed25519"
  fi

  echo
  echo "==== СКОПИРУЙ ЭТОТ SSH-KEY В GIT-ПРОФИЛЬ (Deploy keys / SSH keys) ===="
  cat "$HOME/.ssh/id_ed25519.pub"
  echo "========================================================================"
  echo

  while true; do
    read -rp "${COLOR_ASK}Введите y чтобы продолжить: ${COLOR_RESET}" PROCEED
    if [ "${PROCEED:-}" = "y" ]; then
      break
    fi
  done
}

install_node_git() {
  echo ">>> Установка зависимостей (curl/ca-certificates) + Node.js (NodeSource 20.x) + git + nginx + certbot..."

  sudo apt update
  sudo apt install -y curl ca-certificates gnupg

  # Node.js 20.x (включает npm)
  if ! command -v node >/dev/null 2>&1 || ! node -v | grep -qE '^v20\.'; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  fi
  sudo apt install -y nodejs git nginx certbot python3-certbot-nginx openssl

  echo "Node version: $(node -v 2>/dev/null || echo 'not found')"
  echo "npm version:  $(npm -v 2>/dev/null || echo 'not found')"
}

install_nginx_certbot_only() {
  echo ">>> Установка nginx, certbot..."
  sudo apt update
  sudo apt install -y curl ca-certificates nginx certbot python3-certbot-nginx
}

install_openssh_server() {
  echo ">>> Установка и запуск OpenSSH server..."
  sudo apt update
  sudo apt install -y openssh-server
  sudo systemctl enable --now ssh
}

ensure_deploy_user() {
  echo ">>> Создание пользователя deploy (если отсутствует)..."
  if id "deploy" >/dev/null 2>&1; then
    echo "Пользователь deploy уже существует."
  else
    # Создаём пользователя и задаём пароль (для входа по паролю)
    sudo adduser --gecos "" deploy
    sudo usermod -aG sudo deploy
  fi

  sudo mkdir -p /home/deploy/.ssh
  sudo chown -R deploy:deploy /home/deploy/.ssh
  sudo chmod 700 /home/deploy/.ssh

  # Разрешаем вход по паролю И по ключу БЕЗ правки основного файла sshd_config:
  # создаём override в /etc/ssh/sshd_config.d и валидируем конфиг перед применением.
  echo ">>> Настройка sshd (безопасно): разрешить PasswordAuthentication и PubkeyAuthentication..."

  sudo mkdir -p /etc/ssh/sshd_config.d

  # бэкап на случай отката
  if [ -f /etc/ssh/sshd_config.d/99-custom.conf ]; then
    sudo cp /etc/ssh/sshd_config.d/99-custom.conf /etc/ssh/sshd_config.d/99-custom.conf.bak
  fi

  sudo tee /etc/ssh/sshd_config.d/99-custom.conf >/dev/null <<'EOF'
PasswordAuthentication yes
PubkeyAuthentication yes
EOF

  echo ">>> Проверка конфигурации sshd (sshd -t)..."
  if sudo sshd -t; then
    echo ">>> Конфиг sshd корректный. Перезагружаю ssh..."
    sudo systemctl restart ssh || sudo systemctl restart sshd
  else
    echo ">>> ОШИБКА: sshd_config не прошёл проверку. Откатываю изменения..."
    if [ -f /etc/ssh/sshd_config.d/99-custom.conf.bak ]; then
      sudo mv /etc/ssh/sshd_config.d/99-custom.conf.bak /etc/ssh/sshd_config.d/99-custom.conf
    else
      sudo rm -f /etc/ssh/sshd_config.d/99-custom.conf
    fi

    # повторная проверка после отката
    sudo sshd -t || true
    echo ">>> SSH НЕ перезапускался, чтобы не потерять доступ."
  fi
}

create_gh_actions_ssh_key_for_server() {
  # Генерируем ключ на сервере. Приватный ключ вы добавите в GitHub Secrets как SSH_KEY.
  echo ">>> Генерация SSH-ключа для GitHub Actions (на сервере)..."
  sudo -u deploy mkdir -p /home/deploy/.ssh

  if sudo -u deploy test -f /home/deploy/.ssh/gh_actions_ed25519; then
    echo "Ключ уже существует: /home/deploy/.ssh/gh_actions_ed25519"
  else
    sudo -u deploy ssh-keygen -t ed25519 -C "github-actions@$(hostname)" -N "" -f /home/deploy/.ssh/gh_actions_ed25519
  fi

  local PUB_KEY
  PUB_KEY="$(sudo -u deploy cat /home/deploy/.ssh/gh_actions_ed25519.pub)"

  if sudo -u deploy test -f /home/deploy/.ssh/authorized_keys && sudo -u deploy grep -qF "$PUB_KEY" /home/deploy/.ssh/authorized_keys; then
    echo "Публичный ключ уже добавлен в /home/deploy/.ssh/authorized_keys"
  else
    echo "$PUB_KEY" | sudo -u deploy tee -a /home/deploy/.ssh/authorized_keys >/dev/null
    sudo chown deploy:deploy /home/deploy/.ssh/authorized_keys
    sudo chmod 600 /home/deploy/.ssh/authorized_keys
  fi

  echo
  echo "
>>> SSH-ключ для GitHub Actions создан (будет показан в конце скрипта).
"
  echo "SSH_KEY (приватный ключ, вставить целиком):"
  sudo -u deploy cat /home/deploy/.ssh/gh_actions_ed25519
  echo
  echo "==========================================================================="
  echo
}

ensure_clean_nginx_conf() {
  local DOMAIN
  DOMAIN="$1"

  local NGINX_CONF="/etc/nginx/sites-available/${DOMAIN}.conf"
  local NGINX_LINK="/etc/nginx/sites-enabled/${DOMAIN}.conf"
  local DEFAULT_LINK="/etc/nginx/sites-enabled/default"

  # Удаляем битую ссылку default, чтобы nginx -t не падал
  if [ -L "$DEFAULT_LINK" ] && [ ! -e "$DEFAULT_LINK" ]; then
    echo ">>> Удаляю битую ссылку $DEFAULT_LINK (цель отсутствует)"
    sudo rm -f "$DEFAULT_LINK"
  fi

  if [ -e "$NGINX_CONF" ] || [ -L "$NGINX_LINK" ]; then
    echo ">>> Найден существующий Nginx-конфиг для домена $DOMAIN. Пересоздать?"
    read -rp "${COLOR_ASK}Удалить старый конфиг и создать новый (y/n)? ${COLOR_RESET}" RESET_CONF
    if [ "${RESET_CONF:-}" = "y" ]; then
      sudo rm -f "$NGINX_CONF" "$NGINX_LINK"
    else
      echo ">>> Пропускаю настройку Nginx для $DOMAIN по запросу пользователя."
      return 1
    fi
  fi

  return 0
}

ensure_socket_io_prompt() {
  # Ask once per script run whether to include Socket.IO proxy block in nginx configs.
  if [ -n "${USE_SOCKET_IO:-}" ]; then
    return 0
  fi
  local DEFAULT="y"
  read -rp "${COLOR_ASK}Нужен ли проксирование Socket.IO (подключения /socket.io/) в nginx? (y/n, default: ${DEFAULT}): ${COLOR_RESET}" SOCKET_IN
  SOCKET_IN="${SOCKET_IN:-$DEFAULT}"
  if [ "$SOCKET_IN" = "y" ] || [ "$SOCKET_IN" = "Y" ]; then
    USE_SOCKET_IO="y"
  else
    USE_SOCKET_IO="n"
  fi
}

install_pm2() {
  echo ">>> Установка pm2 глобально..."
  if ! command -v npm >/dev/null 2>&1; then
    echo "npm не найден — устанавливаю nodejs (с npm)..."
    sudo apt update
    sudo apt install -y curl ca-certificates gnupg
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
  fi
  sudo npm install -g pm2
}


maybe_checkout_branch() {
  # Предлагаем переключиться на нужную ветку до установки зависимостей
  if [ -z "${PROJECT_DIR:-}" ]; then
    echo "PROJECT_DIR пустой. Сначала нужно clone_repo."
    return 1
  fi

  cd "$PROJECT_DIR"

  if [ ! -d ".git" ]; then
    echo "Это не git-репозиторий: $PROJECT_DIR"
    return 0
  fi

  echo
  echo ">>> Текущая ветка:"
  git branch --show-current 2>/dev/null || true
  echo

  read -rp "${COLOR_ASK}Переключиться на другую ветку перед установкой зависимостей (y/n)? ${COLOR_RESET}" SW
  if [ "${SW:-}" != "y" ]; then
    return 0
  fi

  echo ">>> Получаю список веток..."
  git fetch --all --prune

  echo ">>> Доступные ветки:"
  git branch -a | sed 's/^..//'
  echo

  read -rp "${COLOR_ASK}Введите имя ветки (например main, dev, origin/dev): ${COLOR_RESET}" BR
  BR="${BR:-}"
  if [ -z "$BR" ]; then
    echo "Ветка не указана — пропускаю."
    return 0
  fi

  if echo "$BR" | grep -qE '^origin/'; then
    LOCAL_BR="${BR#origin/}"
    git checkout -B "$LOCAL_BR" "$BR"
  else
    if git show-ref --verify --quiet "refs/heads/$BR"; then
      git checkout "$BR"
    else
      git checkout -B "$BR" "origin/$BR" || git checkout "$BR"
    fi
  fi

  echo ">>> Текущая ветка: $(git branch --show-current)"
}

clone_repo() {
  echo ">>> Ввод ссылки на репозиторий (SSH или HTTPS)"
  read -rp "${COLOR_ASK}Введите URL репозитория: ${COLOR_RESET}" REPO_URL

  mkdir -p "$HOME/servers"
  cd "$HOME/servers"

  # Имя папки из URL
  REPO_NAME=$(basename -s .git "$REPO_URL")
  TARGET_DIR="$HOME/servers/$REPO_NAME"

  if [ -d "$TARGET_DIR" ]; then
    echo "Папка $TARGET_DIR уже существует."
    read -rp "${COLOR_ASK}Использовать её (y/n)? ${COLOR_RESET}" USE_EXISTING
    if [ "${USE_EXISTING:-}" != "y" ]; then
      read -rp "${COLOR_ASK}Введите новое имя папки: ${COLOR_RESET}" REPO_NAME
      TARGET_DIR="$HOME/servers/$REPO_NAME"
    fi
  fi

  if [ ! -d "$TARGET_DIR/.git" ]; then
    echo ">>> Клонирование в $TARGET_DIR ..."
    git clone "$REPO_URL" "$TARGET_DIR"
  else
    echo "Репозиторий уже клонирован: $TARGET_DIR"
  fi

  PROJECT_DIR="$TARGET_DIR"
  PROJECT_NAME="$REPO_NAME"
  echo ">>> Репозиторий будет использоваться из: $PROJECT_DIR"
}


create_env_file_if_needed() {
  if [ -z "${PROJECT_DIR:-}" ]; then
    return 0
  fi

  cd "$PROJECT_DIR"

  read -rp "${COLOR_ASK}Создать/обновить .env в корне проекта и вставить содержимое сейчас (y/n)? ${COLOR_RESET}" CREATE_ENV
  if [ "${CREATE_ENV:-}" != "y" ]; then
    return 0
  fi

  echo
  echo "${COLOR_OK}Сейчас вставьте содержимое .env в консоль и завершите ввод комбинацией Ctrl+D${COLOR_RESET}"
  echo "${COLOR_OK}Файл будет записан в: $PROJECT_DIR/.env${COLOR_RESET}"
  echo

  cat > "$PROJECT_DIR/.env"

  echo
  echo "${COLOR_OK}.env сохранён: $PROJECT_DIR/.env${COLOR_RESET}"
  echo
}

install_project_dependencies() {
  echo ">>> Установка зависимостей в $PROJECT_DIR ..."
  cd "$PROJECT_DIR"
  if [ -f "package.json" ]; then
    npm install
  else
    echo "Внимание: файл package.json не найден в $PROJECT_DIR. Пропускаю npm install."
  fi
}

setup_certbot_for_domain() {
  local DOMAIN
  DOMAIN="$1"

  echo ">>> Configuring HTTPS (Let's Encrypt, certbot + nginx)..."
  if [ -z "${DOMAIN:-}" ]; then
    read -rp "${COLOR_ASK}Enter domain (example.com): ${COLOR_RESET}" DOMAIN
  fi

  if [ -z "${DOMAIN:-}" ]; then
    echo "Domain is empty, skip certbot."
    return 1
  fi

  CERTBOT_DOMAIN="$DOMAIN"

  # DNS must already point to this server
  echo ">>> Running certbot for domain: $CERTBOT_DOMAIN"
  sudo certbot --nginx -d "$CERTBOT_DOMAIN"

  echo "Certbot installs a systemd timer for automatic renewals."
  echo "Проверка: systemctl list-timers | grep certbot"
}

setup_nginx_backend() {
  local DOMAIN PORT
  DOMAIN="$1"
  PORT="$2"

  ensure_socket_io_prompt
  ensure_clean_nginx_conf "$DOMAIN" || return 0

  echo ">>> Настройка nginx для backend: домен $DOMAIN, порт $PORT (location /api)..."

  local NGINX_CONF="/etc/nginx/sites-available/${DOMAIN}.conf"

  {
    cat <<EOF
  server {
      listen 80;
      server_name $DOMAIN;

EOF
    if [ "${USE_SOCKET_IO}" = "y" ]; then
      cat <<EOF
      location /socket.io/ {
          proxy_pass         http://127.0.0.1:${PORT};
          proxy_http_version 1.1;
          proxy_set_header   Upgrade \$http_upgrade;
          proxy_set_header   Connection "upgrade";
          proxy_set_header   Host \$host;
          proxy_set_header   X-Real-IP \$remote_addr;
          proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
          proxy_set_header   X-Forwarded-Proto \$scheme;
          proxy_read_timeout 60s;
      }

EOF
    fi
    cat <<EOF
      location /api/ {
          proxy_pass         http://127.0.0.1:${PORT}/;
          proxy_http_version 1.1;
          proxy_set_header   Upgrade \$http_upgrade;
          proxy_set_header   Connection "upgrade";
          proxy_set_header   Host \$host;
          proxy_cache_bypass \$http_upgrade;
      }
  }
EOF
  } | sudo tee "$NGINX_CONF" >/dev/null

  sudo ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/${DOMAIN}.conf"
  sudo nginx -t
  sudo systemctl reload nginx
}

setup_nginx_frontend_static() {
  local DOMAIN
  DOMAIN="$1"

  ensure_clean_nginx_conf "$DOMAIN" || return 0

  echo ">>> Настройка nginx для frontend: домен $DOMAIN, статика в /var/www/$DOMAIN/html"

  sudo mkdir -p "/var/www/$DOMAIN/html"
  sudo chown -R deploy:deploy "/var/www/$DOMAIN" || true

  local NGINX_CONF="/etc/nginx/sites-available/${DOMAIN}.conf"

  sudo tee "$NGINX_CONF" >/dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root /var/www/$DOMAIN/html;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

  sudo ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/${DOMAIN}.conf"
  sudo nginx -t
  sudo systemctl reload nginx

  echo "Теперь можно положить файлы сайта в /var/www/$DOMAIN/html"
}

setup_nginx_backend_and_frontend() {
  local DOMAIN PORT
  DOMAIN="$1"
  PORT="$2"

  ensure_socket_io_prompt
  ensure_clean_nginx_conf "$DOMAIN" || return 0

  echo ">>> Настройка nginx для backend+frontend: домен $DOMAIN, backend-порт $PORT"
  echo "    /api -> backend"
  echo "    /   -> статика /var/www/$DOMAIN/html"

  sudo mkdir -p "/var/www/$DOMAIN/html"
  sudo chown -R deploy:deploy "/var/www/$DOMAIN" || true

  local NGINX_CONF="/etc/nginx/sites-available/${DOMAIN}.conf"

  {
    cat <<EOF
  server {
      listen 80;
      server_name $DOMAIN;

EOF
    if [ "${USE_SOCKET_IO}" = "y" ]; then
      cat <<EOF
      location /socket.io/ {
          proxy_pass         http://127.0.0.1:${PORT};
          proxy_http_version 1.1;
          proxy_set_header   Upgrade \$http_upgrade;
          proxy_set_header   Connection "upgrade";
          proxy_set_header   Host \$host;
          proxy_set_header   X-Real-IP \$remote_addr;
          proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
          proxy_set_header   X-Forwarded-Proto \$scheme;
          proxy_read_timeout 60s;
      }

EOF
    fi
    cat <<EOF
      location /api/ {
          proxy_pass         http://127.0.0.1:${PORT}/;
          proxy_http_version 1.1;
          proxy_set_header   Upgrade \$http_upgrade;
          proxy_set_header   Connection "upgrade";
          proxy_set_header   Host \$host;
          proxy_cache_bypass \$http_upgrade;
      }

    root /var/www/$DOMAIN/html;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF
  } | sudo tee "$NGINX_CONF" >/dev/null

  sudo ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/${DOMAIN}.conf"
  sudo nginx -t
  sudo systemctl reload nginx
}

setup_pm2_for_project() {
  echo ">>> Настройка pm2 для проекта $PROJECT_NAME в $PROJECT_DIR"

  cd "$PROJECT_DIR"
  read -rp "${COLOR_ASK}Введите относительный путь к entry-файлу (например, app.js или src/index.js): ${COLOR_RESET}" ENTRY_FILE

  if [ ! -f "$ENTRY_FILE" ]; then
    echo "Предупреждение: файл $ENTRY_FILE не найден. pm2 всё равно попытается его запустить."
  fi

  # Проверяем, есть ли уже процесс с таким именем
  if pm2 describe "$PROJECT_NAME" >/dev/null 2>&1; then
    echo
    echo "${COLOR_ASK}Процесс pm2 с именем '$PROJECT_NAME' уже существует.${COLOR_RESET}"
    pm2 ls || true
    echo
    read -rp "${COLOR_ASK}Удалить существующий процесс и создать заново (y/n)? ${COLOR_RESET}" PM2_DEL
    if [ "${PM2_DEL:-}" = "y" ]; then
      pm2 delete "$PROJECT_NAME" || true
      echo ">>> Удалено. Создаю процесс заново..."
      pm2 start "$ENTRY_FILE" --name "$PROJECT_NAME" --update-env
    else
      echo ">>> Оставляю существующий процесс. Перезапускаю с обновлением окружения..."
      pm2 restart "$PROJECT_NAME" --update-env || true
    fi
  else
    # Процесса нет — запускаем новый
    pm2 start "$ENTRY_FILE" --name "$PROJECT_NAME" --update-env
  fi

  pm2 save

  echo ">>> Настройка автозапуска pm2 (systemd)..."
  sudo env PATH="$PATH" pm2 startup systemd -u "$USER" --hp "$HOME"
}


write_deploy_yml_to_tmp() {
  # Генерация /tmp/deploy.yml (деплой фронтенда через rsync по SSH) + Telegram уведомления.
  # Используем SSH_KEY_B64, чтобы избежать ошибок libcrypto на runner'е.
  # Опционально: FRONTEND_ENV_B64 (base64 содержимого .env) — создаст .env перед сборкой.

  local FRONT_DOMAIN="${1:-}"

  local BRANCH_DEFAULT="main"
  read -rp "${COLOR_ASK}Ветка для автодеплоя (по умолчанию: ${BRANCH_DEFAULT}): ${COLOR_RESET}" BR_IN
  local BRANCH="${BR_IN:-$BRANCH_DEFAULT}"

  local BUILD_CMD_DEFAULT="build"
  read -rp "${COLOR_ASK}Команда сборки (npm run ...) для фронтенда (по умолчанию: ${BUILD_CMD_DEFAULT}): ${COLOR_RESET}" BUILD_IN
  local BUILD_CMD="${BUILD_IN:-$BUILD_CMD_DEFAULT}"

  local REMOTE_DIR
  if [ -n "${FRONT_DOMAIN:-}" ]; then
    REMOTE_DIR="/var/www/${FRONT_DOMAIN}/html"
  else
    REMOTE_DIR="/var/www/DOMAIN/html"
  fi

  cat > /tmp/deploy.yml <<EOF
# Deploy frontend via SSH (rsync)
#
# GitHub Secrets (Repo → Settings → Secrets and variables → Actions):
#   SSH_HOST          = IP/домен сервера
#   SSH_PORT          = 22
#   SSH_USER          = deploy
#   SSH_KEY_B64       = base64 приватного ключа (в одну строку)
#   TG_BOT_TOKEN      = токен Telegram бота (BotFather)
#   TG_CHAT_ID        = chat_id куда слать уведомления
#
# (Опционально для сборки) FRONTEND_ENV_B64 = base64 содержимого .env (в одну строку)
#   - Если Secret FRONTEND_ENV_B64 задан, workflow создаст файл .env перед сборкой.
#   - Для Vite переменные должны быть с префиксом VITE_ (иначе они не попадут в клиентский код).
#
# Как получить SSH_KEY_B64 на сервере (одной строкой):
#   openssl base64 -A -in /home/deploy/.ssh/gh_actions_ed25519
#   (альтернатива) base64 -w0 /home/deploy/.ssh/gh_actions_ed25519
#
# Как получить FRONTEND_ENV_B64 на своём ПК (одной строкой):
#   openssl base64 -A -in .env
#   (альтернатива) base64 -w0 .env
#
# Путь назначения должен совпадать с nginx root:
#   ${REMOTE_DIR}

name: Deploy frontend via SSH

on:
  push:
    branches: ["${BRANCH}"]
  workflow_dispatch:

env:
  FRONTEND_REMOTE_DIR: "${REMOTE_DIR}"

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm

      - name: (Optional) Create .env from secret
        env:
          FRONTEND_ENV_B64: \${{ secrets.FRONTEND_ENV_B64 }}
        if: \${{ env.FRONTEND_ENV_B64 != '' }}
        run: |
          set -euxo pipefail
          echo "\${{ secrets.FRONTEND_ENV_B64 }}" | base64 -d > .env
          tr -d '\r' < .env > .env.tmp && mv .env.tmp .env
          echo ".env создан (первые строки):"
          head -n 5 .env | sed 's/=.*/=<hidden>/'

      - name: Build
        run: |
          set -euxo pipefail
          npm ci
          npm run ${BUILD_CMD}
          test -d dist
          ls -la dist

      - name: Setup SSH (base64 key)
        run: |
          set -euxo pipefail
          mkdir -p ~/.ssh

          echo "\${{ secrets.SSH_KEY_B64 }}" | base64 -d > ~/.ssh/id_ed25519
          tr -d '\r' < ~/.ssh/id_ed25519 > ~/.ssh/id_ed25519.tmp && mv ~/.ssh/id_ed25519.tmp ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519

          ssh-keyscan -p \${{ secrets.SSH_PORT }} -H \${{ secrets.SSH_HOST }} >> ~/.ssh/known_hosts
          ssh-keygen -lf ~/.ssh/id_ed25519

      - name: Upload dist
        run: |
          set -euxo pipefail
          ssh -p \${{ secrets.SSH_PORT }} \${{ secrets.SSH_USER }}@\${{ secrets.SSH_HOST }} \
            "set -eux; mkdir -p '\${{ env.FRONTEND_REMOTE_DIR }}'; ls -la '\${{ env.FRONTEND_REMOTE_DIR }}'; touch '\${{ env.FRONTEND_REMOTE_DIR }}/.write_test' && rm '\${{ env.FRONTEND_REMOTE_DIR }}/.write_test'"

          rsync -az --delete --stats --itemize-changes \
            -e "ssh -p \${{ secrets.SSH_PORT }}" \
            dist/ \${{ secrets.SSH_USER }}@\${{ secrets.SSH_HOST }}:\${{ env.FRONTEND_REMOTE_DIR }}/

      - name: Notify Telegram (success)
        if: success()
        run: |
          set -e
          MSG="✅ Deploy OK
          repo: \$GITHUB_REPOSITORY
          branch: \$GITHUB_REF_NAME
          commit: \$GITHUB_SHA
          actor: \$GITHUB_ACTOR
          run: https://github.com/\$GITHUB_REPOSITORY/actions/runs/\$GITHUB_RUN_ID"
          curl -sS -X POST "https://api.telegram.org/bot\${{ secrets.TG_BOT_TOKEN }}/sendMessage" \
            -d "chat_id=\${{ secrets.TG_CHAT_ID }}" \
            -d "text=\$MSG" >/dev/null

      - name: Notify Telegram (failure)
        if: failure()
        run: |
          set -e
          MSG="❌ Deploy FAILED
          repo: \$GITHUB_REPOSITORY
          branch: \$GITHUB_REF_NAME
          commit: \$GITHUB_SHA
          actor: \$GITHUB_ACTOR
          run: https://github.com/\$GITHUB_REPOSITORY/actions/runs/\$GITHUB_RUN_ID"
          curl -sS -X POST "https://api.telegram.org/bot\${{ secrets.TG_BOT_TOKEN }}/sendMessage" \
            -d "chat_id=\${{ secrets.TG_CHAT_ID }}" \
            -d "text=\$MSG" >/dev/null
EOF

  echo ">>> Создано: /tmp/deploy.yml"
}









print_github_secrets_info() {
  echo
  echo "${COLOR_OK}=== ДОБАВЬТЕ В GitHub Secrets (Settings → Secrets and variables → Actions) ===${COLOR_RESET}"
  echo "${COLOR_OK}SSH_HOST = <IP или домен сервера>${COLOR_RESET}"
  echo "${COLOR_OK}SSH_USER = deploy${COLOR_RESET}"
  echo "${COLOR_OK}SSH_PORT = 22${COLOR_RESET}"
  echo "${COLOR_OK}TG_BOT_TOKEN = <токен Telegram бота>${COLOR_RESET}"
  echo "${COLOR_OK}TG_CHAT_ID = <chat_id>${COLOR_RESET}"
  echo

  echo "${COLOR_OK}SSH_KEY (приватный ключ, вставить целиком):${COLOR_RESET}"
  sudo -u deploy cat /home/deploy/.ssh/gh_actions_ed25519
  echo

  echo "${COLOR_OK}SSH_KEY_B64 (base64 в одну строку):${COLOR_RESET}"
  if command -v openssl >/dev/null 2>&1; then
    sudo -u deploy openssl base64 -A -in /home/deploy/.ssh/gh_actions_ed25519
  elif sudo -u deploy base64 -w0 /home/deploy/.ssh/gh_actions_ed25519 >/dev/null 2>&1; then
    sudo -u deploy base64 -w0 /home/deploy/.ssh/gh_actions_ed25519
  else
    # fallback без tr: через python3
    sudo -u deploy python3 - <<'PY'
import base64
p='/home/deploy/.ssh/gh_actions_ed25519'
print(base64.b64encode(open(p,'rb').read()).decode())
PY
  fi
  echo
  echo "${COLOR_OK}(Опционально для сборки фронта) FRONTEND_ENV_B64 = base64 содержимого вашего .env${COLOR_RESET}"
  echo "${COLOR_OK}  На вашем ПК: base64 -w0 .env    (или: base64 .env | tr -d '\n')${COLOR_RESET}"
  echo "${COLOR_OK}===================================================================${COLOR_RESET}"
  echo
}






offer_download_deploy_yml() {
  if [ ! -f /tmp/deploy.yml ]; then
    return 0
  fi

  local SERVER_HOST
  SERVER_HOST="$(hostname -I 2>/dev/null | awk '{print $1}')"

  echo
  echo "${COLOR_OK}=== ВЫПОЛНИТЕ НА ВАШЕМ КОМПЬЮТЕРЕ ===${COLOR_RESET}"
  echo "${COLOR_OK}mkdir -p ./.github/workflows${COLOR_RESET}"
  echo "${COLOR_OK}scp -P 22 deploy@${SERVER_HOST}:/tmp/deploy.yml ./.github/workflows/deploy.yml${COLOR_RESET}"
  echo "${COLOR_OK}git add .github/workflows/deploy.yml && git commit -m \"add deploy workflow\" && git push${COLOR_RESET}"
  echo "${COLOR_OK}=====================================${COLOR_RESET}"
  echo
}


### ===== Логика режимов =====

echo "Выберите режим установки:"
echo "1) Backend"
echo "2) Frontend"
echo "3) Backend + Frontend"
read -rp "${COLOR_ASK}Введите номер (1/2/3): ${COLOR_RESET}" MODE

case "${MODE:-}" in
  1)
    echo ">>> Backend"
    create_ssh_key
    install_node_git
    install_openssh_server
    ensure_deploy_user
    create_gh_actions_ssh_key_for_server

    clone_repo
    maybe_checkout_branch
    create_env_file_if_needed
    install_project_dependencies

    read -rp "${COLOR_ASK}Домен для backend (example.com): ${COLOR_RESET}" CERTBOT_DOMAIN
    if [ -z "${CERTBOT_DOMAIN:-}" ]; then
      echo "Домен обязателен."
      exit 1
    fi

    read -rp "${COLOR_ASK}Порт backend (например, 3000): ${COLOR_RESET}" BACKEND_PORT
    if [ -z "${BACKEND_PORT:-}" ]; then
      echo "Порт обязателен."
      exit 1
    fi

    setup_nginx_backend "$CERTBOT_DOMAIN" "$BACKEND_PORT"
    setup_certbot_for_domain "$CERTBOT_DOMAIN"

    install_pm2
    setup_pm2_for_project

    # workflow файл в /tmp, чтобы забрать на ПК
    write_deploy_yml_to_tmp "$CERTBOT_DOMAIN" "${ENTRY_FILE:-server.js}"
    offer_download_deploy_yml
    print_github_secrets_info

    echo ">>> Backend настроен (nginx + https + pm2)."
    ;;

  2)
    echo ">>> Frontend"
    create_ssh_key
    install_nginx_certbot_only
    install_openssh_server
    ensure_deploy_user
    create_gh_actions_ssh_key_for_server

    read -rp "${COLOR_ASK}Домен для frontend (example.com): ${COLOR_RESET}" CERTBOT_DOMAIN
    if [ -z "${CERTBOT_DOMAIN:-}" ]; then
      echo "Домен обязателен."
      exit 1
    fi

    setup_nginx_frontend_static "$CERTBOT_DOMAIN"
    setup_certbot_for_domain "$CERTBOT_DOMAIN"

    write_deploy_yml_to_tmp "$CERTBOT_DOMAIN" "server.js"
    offer_download_deploy_yml
    print_github_secrets_info

    echo ">>> Frontend настроен. Статика: /var/www/$CERTBOT_DOMAIN/html"
    ;;

  3)
    echo ">>> Backend + Frontend"
    create_ssh_key
    install_node_git
    install_openssh_server
    ensure_deploy_user
    create_gh_actions_ssh_key_for_server

    clone_repo
    maybe_checkout_branch
    create_env_file_if_needed
    install_project_dependencies

    read -rp "${COLOR_ASK}Домен (example.com): ${COLOR_RESET}" CERTBOT_DOMAIN
    if [ -z "${CERTBOT_DOMAIN:-}" ]; then
      echo "Домен обязателен."
      exit 1
    fi

    read -rp "${COLOR_ASK}Порт backend (например, 3000): ${COLOR_RESET}" BACKEND_PORT
    if [ -z "${BACKEND_PORT:-}" ]; then
      echo "Порт обязателен."
      exit 1
    fi

    setup_nginx_backend_and_frontend "$CERTBOT_DOMAIN" "$BACKEND_PORT"
    setup_certbot_for_domain "$CERTBOT_DOMAIN"

    install_pm2
    setup_pm2_for_project

    write_deploy_yml_to_tmp "$CERTBOT_DOMAIN" "${ENTRY_FILE:-server.js}"
    offer_download_deploy_yml
    print_github_secrets_info

    echo ">>> Backend настроен (pm2). Frontend папка: /var/www/$CERTBOT_DOMAIN/html"
    ;;

  *)
    echo "Нужно выбрать 1, 2 или 3."
    exit 1
    ;;
esac
