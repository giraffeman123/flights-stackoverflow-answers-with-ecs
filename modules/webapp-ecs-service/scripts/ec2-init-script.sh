#!/bin/bash

#Instalacion paquetes necesarios
sudo apt-get update

#install unzip package
sudo apt-get -y install unzip
sudo apt-get -y install curl

#install java 17
sudo apt-get -y install openjdk-17-jdk openjdk-17-jre
export JAVA_HOME="/usr/lib/jvm/java-1.17.0-openjdk-amd64"
java -version

#install maven
sudo apt-get -y install maven
mvn -version

#install and configure tomcat 10.1.25
sudo mkdir /opt/tomcat
cd /tmp
#you can choose either the binary found in repository or validate if the link to apache site is still working...
curl https://raw.githubusercontent.com/giraffeman123/flights-stackoverflow-answers/main/infra-resources/apache-tomcat-10.1.25.zip --output apache-tomcat-10.1.25.zip
sudo unzip apache-tomcat-10.1.25.zip
sudo mv apache-tomcat-10.1.25/* /opt/tomcat

# wget https://archive.apache.org/dist/tomcat/tomcat-10/v10.1.25/bin/apache-tomcat-10.1.25.tar.gz
# sudo tar xzvf apache-tomcat-10*tar.gz -C /opt/tomcat --strip-components=1

sudo chown -R ubuntu:ubuntu /opt/tomcat/
sudo chmod -R u+x /opt/tomcat/bin

cat > /home/ubuntu/tomcat.service <<EOF
[Unit]
Description=Tomcat
After=network.target

[Service]
Type=forking

User=ubuntu

Environment="JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
Environment="SERVER_PORT=${app_port}"
Environment="XAL_DIGITAL_API_BASE_URL=http://${fsa_api_base_url}"

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF


sudo mv /home/ubuntu/tomcat.service /etc/systemd/system/

#configure environment variables for tomcat
cat > /home/ubuntu/setenv.sh <<EOF
export JAVA_HOME="/usr/lib/jvm/java-1.17.0-openjdk-amd64"
export JAVA_OPTS="-Djava.security.egd=file:///dev/urandom"
export CATALINA_BASE="/opt/tomcat"
export CATALINA_HOME="/opt/tomcat"
export CATALINA_PID="/opt/tomcat/temp/tomcat.pid"
export CATALINA_OPTS="-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
export SERVER_PORT="${app_port}"
export XAL_DIGITAL_API_BASE_URL="http://${fsa_api_base_url}"
EOF

sudo mv /home/ubuntu/setenv.sh /opt/tomcat/bin

#restart systemd and start tomcat
sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl start tomcat
sudo systemctl status tomcat

#install and configure java spring boot project
cd /home/ubuntu
git clone https://github.com/giraffeman123/tech-interview-xaldigital.git
cd tech-interview-xaldigital/web-app/
sudo mvn clean package
sudo chown -R ubuntu:ubuntu target/WebApp.war
sudo mv /home/ubuntu/tech-interview-xaldigital/web-app/target/WebApp.war /opt/tomcat/webapps/ROOT.war
sudo rm -rf /opt/tomcat/webapps/ROOT/

sudo systemctl restart tomcat

#install, configure and start cloudwatch agent
mkdir /tmp/cloudwatch-logs && cd /tmp/cloudwatch-logs
sudo wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
sudo dpkg -i -E ./amazon-cloudwatch-agent.deb

sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:${ssm_cloudwatch_config} -s
