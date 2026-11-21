#!/usr/bin/env bash
# Rejoue les commandes du cours Docker dont la sortie est marquée « à rejouer » dans les notes de l'orateur,
# et relève les versions. À lancer sur un Debian 13 avec docker.io (26.1.5), AppArmor actif, utilisateur du
# groupe docker et accès sudo : ./rejouer.sh > sorties-docker.txt 2>&1
# Les commandes interactives (bash, ssh) ne sont pas rejouées ; tout est créé dans un dossier temporaire.
set -u
run() { printf '\n$ %s\n' "$1"; bash -c "$1" 2>&1; }
D=$(mktemp -d); cd "$D" || exit 1
echo "# $(date -I) · $(uname -srm) · $D"

# Versions
run 'docker version --format "{{.Server.Version}}"'
run 'docker compose version'
run 'docker buildx version'

# Bases
run 'docker container run --rm debian:13 /bin/ls'
run 'docker container run --name hw hello-world >/dev/null; docker container ls -a | head -3; docker container rm hw'
run 'docker container prune -f'
run 'docker container run ubuntu /bin/ps -eflH'
run 'docker info | grep -A3 "Security Options"'
run 'docker container run -d --name ctA alpine sleep infinity >/dev/null; docker container exec ctA ip route; docker container rm -f ctA'
run 'docker network create app && docker container run -d --network app --name web nginx && docker container run --rm --network app alpine nslookup web; docker container rm -f web; docker network rm app'
run 'docker container run -d --name web -p 8080:80 nginx:1.29-alpine >/dev/null; sleep 2; curl -s localhost:8080 >/dev/null; docker container logs web | tail -1; docker container rm -f web'

# Persistance : piège du montage écrit en root
run 'mkdir -p partage && docker container run --rm -v "$PWD/partage:/data" debian:13 sh -c "mkdir /data/build && touch /data/build/sortie" && ls -ln partage; rm -rf partage/build; sudo rm -rf partage'

# Dockerfile : fil rouge hello
printf 'server {\n  listen 80;\n  default_type text/plain;\n  location / {\n    return 200 "Bonjour depuis $hostname\\n";\n  }\n}\n' > hello.conf
printf 'FROM nginx:1.29-alpine\nCOPY hello.conf /etc/nginx/conf.d/default.conf\nEXPOSE 80\nHEALTHCHECK --interval=5s \\\n  CMD wget -qO- http://localhost/ || exit 1\n' > Dockerfile
run 'DOCKER_BUILDKIT=0 docker image build -t hello-legacy .'
run 'docker image build -t hello . && docker image history --format "table {{.CreatedBy}}\t{{.Size}}" hello | head -5'
run 'sed -i s/Bonjour/Salut/ hello.conf && docker image build -q -t hello . && docker image ls -a && docker system df'
run 'docker image prune -f; docker builder prune -f'

# Variables dans un Dockerfile
mkdir -p var && printf 'FROM debian:13\nENV APP_DIR=/app\nWORKDIR ${APP_DIR}\nLABEL p="${PATH}" h="[${HOME}]"\n' > var/Dockerfile
run 'docker image build -q -t variables var && docker image inspect -f "{{json .Config.Labels}}" variables'

# Forme shell : ENTRYPOINT enregistré
mkdir -p fs && printf 'FROM debian:13\nENTRYPOINT echo HOME=$HOME bonjour\n' > fs/Dockerfile
run 'docker image build -q -t forme-shell fs && docker image inspect -f "{{json .Config.Entrypoint}}" forme-shell'

# Dockerfile ping
mkdir -p ping && printf 'FROM debian:13\nRUN apt-get update && apt-get install -y inetutils-ping && rm -rf /var/lib/apt/lists/*\nCMD ["ping", "-c", "2", "localhost"]\n' > ping/Dockerfile
run 'docker image build -q -t mon_image ping && docker container run --rm mon_image'

# Sécurité : no-new-privileges sur un binaire setuid
run 'docker container run --rm --security-opt no-new-privileges debian:13 sh -c "cp /bin/id /tmp/id && chmod u+s /tmp/id && ls -l /tmp/id && /tmp/id -u"'

echo; echo '# Nettoyage'
docker image rm -f hello hello-legacy variables forme-shell mon_image >/dev/null 2>&1
rm -rf "$D"
