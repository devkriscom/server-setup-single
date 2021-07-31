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

curl -sO https://raw.githubusercontent.com/wordspec/server-setup-single/master/cloner.sh
chmod +x cloner.sh 

2. Check credentials
$ cat /home/.dbrootpass  => to check root mysql password

# Step  2: Setup MySQL  
1. Get root mysql user  
