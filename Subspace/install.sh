#!/bin/bash

function install_tools {
  sudo apt update && sudo apt install mc wget htop jq git -y
}

function install_docker {
  curl -s https://raw.githubusercontent.com/IT-GANG-NODES/tools/blob/main/docker.sh | bash
}

function install_ufw {
  curl -s https://raw.githubusercontent.com/IT-GANG-NODES/tools/blob/main/ufw.sh | bash
}

function read_nodename {
  if [ ! $SUBSPACE_NODENAME ]; then
  echo -e "Enter your node name(random name for telemetry)"
  read SUBSPACE_NODENAME
  fi
}

function read_wallet {
  if [ ! $WALLET_ADDRESS ]; then
  echo -e "Enter your polkadot.js extension address"
  read WALLET_ADDRESS
  fi
}

function plot_size {
  if [ ! $PLOT_SIZE ]; then
  echo -e "Enter your plot size(default is 100G)"
  read PLOT_SIZE
  fi
}

function get_vars {
  export CHAIN="gemini-3h"
  export RELEASE="gemini-3h-2024-sep-17"
}

function eof_docker_compose {
  mkdir -p $HOME/subspace_docker/
  sudo tee <<EOF >/dev/null $HOME/subspace_docker/docker-compose.yml
  version: "3.7"
  services:
    node:
      image: ghcr.io/autonomys/node:$RELEASE
      volumes:
        - node-data:/var/subspace:rw
      ports:
        - "0.0.0.0:32333:30333/udp"
        - "0.0.0.0:32333:30333/tcp"
        - "0.0.0.0:32433:30433/udp"
        - "0.0.0.0:32433:30433/tcp"
      restart: unless-stopped
      command:
        [
          "run",
          "--base-path", "/var/subspace",
          "--chain", "gemini-3h",
          "--blocks-pruning", "256",
          "--state-pruning", "140000",
          "--farmer",
          "--rpc-listen-on", "0.0.0.0:9944",
          "--rpc-cors", "all",
          "--rpc-methods", "unsafe",
          "--name", "$SUBSPACE_NODENAME"
        ]
      healthcheck:
        timeout: 5s
        interval: 30s
        retries: 60

    farmer:
      depends_on:
        node:
          condition: service_healthy
      image: ghcr.io/autonomys/farmer:$RELEASE
      volumes:
        - farmer-data:/var/subspace:rw
      ports:
        - "0.0.0.0:32533:30533/udp"
        - "0.0.0.0:32533:30533/tcp"
      restart: unless-stopped
      command:
        [
          "farm",
          "--node-rpc-url", "ws://node:9944",
          "--reward-address", "$WALLET_ADDRESS",
          "path=/var/subspace,size=$PLOT_SIZE"
        ]
  volumes:
    node-data:
    farmer-data:            
EOF
}

function docker_compose_up {
  docker-compose -f $HOME/subspace_docker/docker-compose.yml up -d
}


function delete_old {
  docker-compose -f $HOME/subspace_docker/docker-compose.yml down -v &>/dev/null
  docker volume rm subspace_docker_subspace-farmer subspace_docker_subspace-node &>/dev/null
}


read_nodename
read_wallet
plot_size
echo -e "Install tools, ufw, docker"
install_tools
install_ufw
install_docker
get_vars
delete_old
echo -e "Create docker-compose file"
eof_docker_compose
echo -e "Start the docker containers for node and farmer Subspace"
docker_compose_up