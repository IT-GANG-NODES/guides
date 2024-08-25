#!/bin/bash

function install_tools {
  sudo apt update && sudo apt install mc wget htop jq git -y
}

function install_docker {
  curl -s https://raw.githubusercontent.com/IT-GANG-NODES/tools/main/docker.sh | bash
}

function install_ufw {
  curl -s https://raw.githubusercontent.com/IT-GANG-NODES/tools/main/ufw.sh | bash
}

function read_sepolia_rpc {
  if [ ! $RPC_URL ]; then
  echo -e "Enter the https URL of your RPC Sepolia. - https://sepolia.infura.io/v3/YOUR_KEY"
  line_1
  read RPC_URL
  fi
}

function read_private_key {
  if [ ! $WAKU_PRIVATE_KEY ]; then
  echo -e "Enter your private ETH wallet that has at least 0.1 ETH in the Sepolia network"
  line_1
  read WAKU_PRIVATE_KEY
  fi
}

function read_pass {
  if [ ! $WAKU_PASS ]; then
  echo -e "Enter (create) a password"
  line_1
  read WAKU_PASS
  fi
}

function git_clone {
  git clone https://github.com/waku-org/nwaku-compose
}

function setup_env {
  cd nwaku-compose
  cp .env.example .env

  sed -i "s|RLN_RELAY_ETH_CLIENT_ADDRESS=.*|RLN_RELAY_ETH_CLIENT_ADDRESS=$RPC_URL|" $HOME/nwaku-compose/.env
  sed -i "s|ETH_TESTNET_KEY=.*|ETH_TESTNET_KEY=$WAKU_PRIVATE_KEY|" $HOME/nwaku-compose/.env
  sed -i "s|RLN_RELAY_CRED_PASSWORD=.*|RLN_RELAY_CRED_PASSWORD=$WAKU_PASS|" $HOME/nwaku-compose/.env
  sed -i "s|NWAKU_IMAGE=.*|NWAKU_IMAGE=harbor.status.im/wakuorg/nwaku:v0.31.0|" $HOME/nwaku-compose/.env


  sed -i 's/0\.0\.0\.0:3000:3000/0.0.0.0:3004:3000/g' $HOME/nwaku-compose/docker-compose.yml
  sed -i 's/127\.0\.0\.1:4000:4000/0.0.0.0:4044:4000/g' $HOME/nwaku-compose/docker-compose.yml

  bash $HOME/nwaku-compose/register_rln.sh
}


function docker_compose_up {
  docker compose -f $HOME/nwaku-compose/docker-compose.yml up -d
}

function echo_info {
  echo -e "${GREEN}To stop the waku node: ${NORMAL}"
  echo -e "${RED}   docker-compose -f $HOME/nwaku-compose/docker-compose.yml down \n ${NORMAL}"
  echo -e "${GREEN}To start a node and a waku farmer: ${NORMAL}"
  echo -e "${RED}   docker-compose -f $HOME/nwaku-compose/docker-compose.yml up -d \n ${NORMAL}"
  echo -e "${GREEN}To reboot the waku node: ${NORMAL}"
  echo -e "${RED}   docker-compose -f $HOME/nwaku-compose/docker-compose.yml restart \n ${NORMAL}"
  echo -e "${GREEN}To check the node logs, run the command: ${NORMAL}"
  echo -e "${RED}   docker-compose -f $HOME/nwaku-compose/docker-compose.yml logs -f --tail=100 \n ${NORMAL}"
  ip_address=$(hostname -I | awk '{print $1}') >/dev/null
  echo -e "${GREEN}To check the Grafana dashboard, follow the link: ${NORMAL}"
  echo -e "${RED}   http://$ip_address:3004/d/yns_4vFVk/nwaku-monitoring \n ${NORMAL}"
}

logo
read_sepolia_rpc
read_private_key
read_pass
echo -e "Installing tools, ufw, docker"
install_tools
install_ufw
install_docker
echo -e "Clone the repository, prepare env and register rln"
git_clone
setup_env
echo -e "Launching docker containers for waku"
docker_compose_up
echo_info