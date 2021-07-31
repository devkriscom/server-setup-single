Server  : Single Server  
-> OS 	: Ubuntu 20.4 Server  
-> RAM 	: 8GB+  
-> Core : 4 core+  
IP5DDR  : 192.x.x.x  
DOMAIN  : wordspec.com pointed to server ip  
DOMAIN  : panel.wordspec.com pointed to server ip  
 
# Step  1: Install
1. auto installer  

apt install -y curl
curl -sO https://raw.githubusercontent.com/wordspec/server-setup-single/master/attach.sh
chmod +x attach.sh
bash ./attach.sh 

curl -sO https://raw.githubusercontent.com/wordspec/server-setup-single/master/create.sh
chmod +x create.sh 
bash ./create.sh



2. Check credentials  
$ cat /home/.dbrootpass  => to check root mysql password  

# Step  2: Create virtual host   
1. Create virtual host  
$ xdomain create {domain:www?.domain.com} {ssl:auto|none}  

2. Install cms/apps  
$ xrecipe domain.com {app:phpmyadmin|wp}  

Tips 1: Clone from other server
1. Login to other server ssh
=> Install cloner
$ curl -sO https://raw.githubusercontent.com/wordspec/server-setup-single/master/cloner.sh  
$ chmod +x cloner.sh  
$ ./cloner.sh {to_domain} {from_db_name} {from_db_user} {from_db_pass} {from_public_html} {to_ip} 

