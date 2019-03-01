#!/bin/bash

source .env

echo_statement() {
  echo ""
  echo -e "\033[0;35m ========== ${1} =========== \033[0m"
}

install_node() {
  echo_statement "Setting up node environment"
  curl -sL https://deb.nodesource.com/setup_10.x -o nodesource_setup.sh
  sudo bash nodesource_setup.sh 
  sudo apt-get install -y nodejs
}

clone_github_repo() {
  echo_statement "Cloning github repository"
  if [[ -d balder-ah-frontend ]]; then
    sudo rm -r balder-ah-frontend
  fi
  git clone ${GitHub_Repo}
}

install_dependencies() {
  echo_statement "Installing project dependencies"
  cd balder-ah-frontend
  sudo npm install node-pre-gyp -ES --unsafe-perm=true
  sudo npm i -ES --unsafe-perm=true
}

build_webpack() {
  echo_statement "Building Webpack"
  sudo npm run build
}

config_server="
  server  {
    server_name ${Domain} ${www_Domain};
    location / {
      proxy_pass http://127.0.0.1:3000;
    }
  }
"

configure_NGINX() {
  echo_statement "Configuring NGINX reverse proxy server"
  sudo apt-get install nginx -y
  sudo rm -r /etc/nginx/sites-enabled/default
  sudo echo ${config_server} > /etc/nginx/sites-available/balder-ah
  sudo ln -s /etc/nginx/sites-available/balder-ah /etc/nginx/sites-enabled/balder-ah
  sudo service nginx restart
}

configure_SSL() {
  echo_statement "Configuring SSL Certificate"
  sudo apt-get update
  sudo apt-get install software-properties-common
  sudo add-apt-repository ppa:certbot/certbot -y
  sudo apt-get update
  sudo apt-get install certbot python-certbot-nginx -y
  sudo certbot --nginx  -d ${Domain} -d ${www_Domain} -m ${Email} --agree-tos --non-interactive
}

start_script='
  {
    "apps": [
      {
        "name": "authors-haven",
        "script": "npm",
        "args": "run start:dev"
      }
    ]
  }
'

keep_App_Alive() {
  echo_statement "Install PM2 to run app in background"
  sudo npm install pm2 -g
  sudo echo ${start_script} > ./start_script.config.json
  pm2 start start_script.config.json
}

main() {
  install_node
  clone_github_repo
  install_dependencies
  build_webpack
  configure_NGINX
  configure_SSL
  keep_App_Alive
}

main
