#!/bin/bash

#Instalacion paquetes necesarios
sudo apt-get update
sudo apt-get -y install mysql-client-core-8.0

#configure environment variables for tomcat
cat > /home/ubuntu/setenv.sh <<EOF
export DATABASE_ENDPOINT="${DATABASE_ENDPOINT}"
export DATABASE_NAME="${DATABASE_NAME}"
export DATABASE_USER="${DATABASE_USER}"
export DATABASE_PASSWORD="${DATABASE_PASSWORD}"
export DATABASE_PORT="${DATABASE_PORT}"
EOF

cat > /home/ubuntu/init.sql <<EOF 
${BOOTSTRAP_DB_SCRIPT}
EOF

mysql 	--host=${DATABASE_ENDPOINT} \
		--port=${DATABASE_PORT} \
		--user=${DATABASE_USER} \
		--password='${DATABASE_PASSWORD}' \
		${DATABASE_NAME} \
		< /home/ubuntu/init.sql

sudo shutdown now