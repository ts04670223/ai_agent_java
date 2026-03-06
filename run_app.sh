#!/bin/bash
cd /vagrant
# Using script to force PTY allocation for unbuffered output
# -q: quiet
# -c: command
script -q -c "mvn spring-boot:run" /vagrant/app.log
