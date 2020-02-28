#!/bin/bash

yum update -yum
yum install -y httpd.86_64
systemctl start httpd.service
systemctl enable httpd.service
echo "Hello world from $(hostname -f)" > /var/www/html/index.html

