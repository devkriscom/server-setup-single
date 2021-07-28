Server  : Single Server  
-> OS 	: Ubuntu 20.4 Server  
-> RAM 	: 8GB+  
-> Core : 4 core+  
IP5DDR  : 192.x.x.x  
DOMAIN  : wordspec.com pointed to server ip  
DOMAIN  : managedb.wordspec.com pointed to server ip  
 
# Step  1: Install dependencies  
1. download and run installer  
$ cd /home  
$ apt install -y -qq curl
$ curl -sO https://bitbucket.org/wordspec/single-server/src/master/install.sh  
$ chmod +x install.sh  
$ ./install.sh  

# Step  1: Setup MySQL  
1. Secure root user  
Create password for root user and save to hidden file to use by future bash script.  
$  mysql_secure_installation  
-> username: root  
-> password: rootpassql  
$  echo "rootpassql" > /home/.mysql_root_password  

# Step  2: Setup Litespeed admin password  

1. Create Admin Password  
$  sudo /usr/local/lsws/admin/misc/admpass.sh  
-> username: lsadmin  
-> password: lsadminpass  
-> adminuri: http://192.x.x.x:7080/login.php  

2. Create HTTP(80) Listener  
-> Listener Name 	: HTTP  
-> IP Address	 		: ANY IPv4  
-> Port	       		: 80  
-> Secure	     		: No  

3. Create HTTPS(443) Listener  
-> Listener Name 	: HTTPs  
-> IP Address	 		: ANY IPv4  
-> Port	       		: 443  
-> Secure	     		: Yes  


# Step  3: Tuneup basic configuration  

1. Update php.ini configuration  
$  sed -i 's,^max_execution_time =.*$,post_max_size = 60,' /usr/local/lsws/lsphp74/etc/php/7.4/litespeed/php.ini  
$  sed -i 's,^memory_limit =.*$,memory_limit = 2048M,' /usr/local/lsws/lsphp74/etc/php/7.4/litespeed/php.ini  
$  sed -i 's,^post_max_size =.*$,post_max_size = 128M,' /usr/local/lsws/lsphp74/etc/php/7.4/litespeed/php.ini  
$  sed -i 's,^upload_max_filesize =.*$,upload_max_filesize = 128M,' /usr/local/lsws/lsphp74/etc/php/7.4/litespeed/php.ini 

$  killall -9 lsphp 

2. Update mysql configuration 
add optimized configuration from folder config/mysql.cnf 
$  curl -sO https://bitbucket.org/wordspec/single-server/src/master/config/mysql.cnf 
$  mv mysql.cnf /etc/mysql/conf.d/optimy.cnf 
$  systemctl restart mysql 

# Step  4: Install support apps 
1. Install postfix and phpmailer 
PHP mail should only use by admin, any commercial email should be routed using 3rd party smtp server. 
$  apt install -y postfix 
$  apt install -y mailutils
=> Select Internet Site and press ENTER.
=> System mail name should be your domain name eg. example.com, press ENTER.
$  nano /etc/postfix/main.cf
-> inet_interfaces = loopback-only
$  sudo systemctl restart postfix
$  echo "Test Email message body" | mail -s "Email test subject" test@example.com

# Step  5: Install monitoring & tracking 
1. Install nodequery
=> register nodequery.com 
-> username: typex.id@gmail.com
-> password: makan123
=> copy command line to install from nodequery.com
=> {copy_installation_command} on terminal and enter

# Step  6: Create bash utilities
1. Bash to create virual host
Script to create virtual host from command line. Script require /home/.mysql_root_password with password
$  xdomain requirement
=> output should be 'all ok', vhost require /home/.mysql_root_password

3. Bash to backup database
Script to backup database separately. Script requires foder /home/backups to be exists and /home/.mysql_root_password with password
$  xdbsave requirement
=> output should be 'all ok'

3. Bash to backup directory
Script to backup site file separately. Script requires foder /home/backups to be exists and /home/.site_backups with list folder need to be backup
$  xdrsave requirement
=> output should be 'all ok'

4. Bash to backup remotely
Script to backup file to remote. Script requires foder /home/backups as source and /home/.remote_backup with list of destination
$  xbackup requirement
=> output should be 'all ok'


# Step  6: Install PHPMyAdmin
1. create virtual host using manual or xvhost

%  Manual
a. Create user
$  sudo useradd -m managedb
$  passwd managedb
-> password: userpass

b. Setup virtual host
-> Virtual Host Name 							:	managedb.wordspec.com
-> Virtual Host Root 							:	/home/managedb
-> Config File       							:	$SERVER_ROOT/conf/vhosts/$VH_NAME/vhconf.conf
-> Document Root    					  	:	$VH_ROOT/html
Create lsphp on external apps #
-> Name													  : lsphp74
-> Address	uds 									: //tmp/lshttpd/lsphp74.sock
-> Notes													: Not Set
-> Max Connections								: 5
-> Environment										: LSAPI_AVOID_FORK=200M
-> Initial Request Timeout       	:	60
-> Retry Timeout (secs)						: 0
-> Persistent Connection 					:	Yes
-> Connection Keep-Alive Timeout	:	Not Set
-> Response Buffering							: No
-> Start By Server								: Yes (Through CGI Daemon)
-> Command												: lsphp74/bin/lsphp
-> Back Log 											: 100
-> Instances											: 1
-> Run As User										: managedb
-> Run As Group 									: managedb
-> Priority												: 0

c. Add Virtual host to HTTP listener

%  Using virtual host bash
$  xvhost create managedb managedb.wordspec.com
-> password: userpass
$  mkdir /home/managedb/html

2. clone phpmyadmin file
$  cd /home/managedb/html
$  wget https://files.phpmyadmin.net/phpMyAdmin/5.1.1/phpMyAdmin-5.1.1-all-languages.zip
$  unzip phpMyAdmin-5.1.1-all-languages.zip
$  cp -r phpMyAdmin-5.1.1-all-languages/* ./
$  rm -rf phpMyAdmin-5.1.1-all-languages phpMyAdmin-5.1.1-all-languages.zip

3. access phpmyadmin managedb.wordspec.com


# Step  7: Creating virtual host for domain

1. create virtual host using manual or xvhost

%  Manual
a. Create user
$  sudo useradd -m wordspec
$  passwd wordspec
-> password: wps@123!Auser
$  mkdir /home/wordspec/html

b. Setup virtual host
-> Virtual Host Name 							:	wordspec.com
-> Virtual Host Root 							:	/home/wordspec
-> Config File       							:	$SERVER_ROOT/conf/vhosts/$VH_NAME/vhconf.conf
-> Document Root    					  	:	$VH_ROOT/html

Create lsphp on external apps #
-> Name													  : lsphp74
-> Address	uds 									: //tmp/lshttpd/lsphp74.sock
-> Notes													: Not Set
-> Max Connections								: 5
-> Environment										: LSAPI_AVOID_FORK=200M
-> Initial Request Timeout       	:	60
-> Retry Timeout (secs)						: 0
-> Persistent Connection 					:	Yes
-> Connection Keep-Alive Timeout	:	Not Set
-> Response Buffering							: No
-> Start By Server								: Yes (Through CGI Daemon)
-> Command												: lsphp74/bin/lsphp
-> Back Log 											: 100
-> Instances											: 1
-> Run As User										: wordspec
-> Run As Group 									: wordspec
-> Priority												: 0
-> Memory Soft Limit (bytes) 		  :	2047M
-> Memory Hard Limit (bytes) 		  :	2047M
-> Process Soft Limit						  : 1400
-> Process Hard Limit						  : 1500

c. request ssl
$ certbot certonly --webroot -w /home/wordspec/html/ -d wordspec.com -d www.wordspec.com

d. update virtual host ssl configuration
-> Private Key File		: /etc/letsencrypt/live/wordspec.com/privkey.pem
-> Certificate File		: /etc/letsencrypt/live/wordspec.com/fullchain.pem
-> Chained Certificate: Yes
-> CA Certificate Path: /etc/letsencrypt/live/wordspec.com/fullchain.pem
-> CA Certificate File: /etc/letsencrypt/live/wordspec.com/fullchain.pem

e. update rewrite rule to redirect http to https(optional)  
-> RewriteCond %{SERVER_PORT} 80  
-> RewriteRule ^(.*)$ https://wordspec.com/$1 [R,L]  
f. add wordspec.com virtual host on HTTP and HTTPS Listener  

g. create MySQL user and database
$ mysql -u root -p -e "CREATE DATABASE wordspec;"
$ mysql -u root -p -e "CREATE USER 'wordspec'@'%' IDENTIFIED BY 'userdbpass';"
$ mysql -u root -p -e "GRANT ALL PRIVILEGES ON *.* TO 'wordspec'@'%';"
$ mysql -u root -p -e "FLUSH PRIVILEGES;"
$ mysql -u root -p -e "SHOW GRANTS FOR 'wordspec'@'%';"

%  Using virtual host bash
$  xvhost create wordspec wordspec.com
-> password: userpass
=> your mysql for user wordspec on /home/wordspec/.mysql_user_password

