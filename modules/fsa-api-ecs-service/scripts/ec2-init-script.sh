#!/bin/bash

#Instalacion paquetes necesarios
sudo apt-get update

#nodejs & npm installation
curl -fsSL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
sudo -E bash nodesource_setup.sh
sudo apt-get -y install nodejs
node -v
#sudo apt-get -y install npm
npm -v

#we clone api repository and install project dependencies 
cd /home/ubuntu/
git clone https://github.com/giraffeman123/tech-interview-xaldigital.git
cd tech-interview-xaldigital/api/
sudo npm install --production

#create directory for app logs
sudo mkdir /var/log/fsa-api

#we add the api as a service unit in systemd service manager 
cat > /home/ubuntu/fsa-api.service <<EOF
[Unit]
Description=API that gets latest flight in simulated airline and also gets information about stack overflow site answers
After=network.target
[Service]
ExecStart=/usr/bin/node /home/ubuntu/tech-interview-xaldigital/api/index.js
WorkingDirectory=/home/ubuntu/tech-interview-xaldigital/api
Restart=always
User=ubuntu
Environment="PATH=/usr/bin:/usr/local/bin"
Environment="NODE_ENV=production"
Environment="PORT=${app_port}"
Environment="DB_HOST=${db_host}"
Environment="DB_USER=${db_admin_user}"
Environment="DB_PWD=${db_pwd}"
Environment="DB_NAME=${db_name}"
Environment="ANSWER_ENDPOINT=${answer_endpoint}"
StandardOutput=file:/var/log/fsa-api/logs.log
StandardError=file:/var/log/fsa-api/logs.log
[Install]
WantedBy=multi-user.target
EOF

sudo mv /home/ubuntu/fsa-api.service /etc/systemd/system/

#create link to nodejs executable
sudo ln -s "$(which node)" /usr/bin/node

#we enable the service, start it and check status
sudo systemctl enable fsa-api
sudo systemctl start fsa-api
sudo systemctl status fsa-api

#install, configure and start cloudwatch agent
mkdir /tmp/cloudwatch-logs && cd /tmp/cloudwatch-logs
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:${ssm_cloudwatch_config} -s

#install, configure and start ssm-agent
sudo mkdir /tmp/ssm && cd /tmp/ssm
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
sudo dpkg -i amazon-ssm-agent.deb
sudo systemctl enable amazon-ssm-agent
rm amazon-ssm-agent.deb