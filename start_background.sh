#!/bin/bash
cd /vagrant
# Run in background with nohup, redirecting all output to app.log
# using stdbuf to minimize buffering
nohup stdbuf -oL mvn spring-boot:run > /vagrant/app.log 2>&1 &
echo "Spring Boot application started in background with PID $!"
