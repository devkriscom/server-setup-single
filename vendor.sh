#!/bin/sh

$ sudo chmod -R 770 /home/wordspec/html
$ sudo find /home/wordspec/html -type d -exec chmod 0755 {} \;
$ sudo find /home/wordspec/html -type f -exec chmod 0644 {} \;

sudo chown -R nobody:nogroup /usr/local/lsws/Example/html/wordpress
sudo find /usr/local/lsws/Example/html/wordpress/ -type d -exec chmod 750 {} \;
sudo find /usr/local/lsws/Example/html/wordpress/ -type f -exec chmod 640 {} \;