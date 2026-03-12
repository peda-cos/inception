#!/bin/bash

mkdir -p /var/log/lighttpd
chown -R www-data:www-data /var/log/lighttpd

mkdir -p /run/php
chown -R www-data:www-data /run/php

php-fpm8.2 -D

lighttpd -D -f /etc/lighttpd/lighttpd.conf
