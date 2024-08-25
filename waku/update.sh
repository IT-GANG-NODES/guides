#!/bin/bash

function colors {
  GREEN="\e[32m"  # Green color
  RED="\e[39m"    # Red color
  NORMAL="\e[0m"  # Reset color
}

function cleanup {
  # Stop and remove docker containers
  docker-compose -f $HOME/nwaku-compose/docker-compose.yml down
  mkdir -p $HOME/nwaku_backups
  if [ -d "$HOME/nwaku_backups/keystore0.30" ]; then
    echo "Backup already done"
  else
    echo "Creating key backup"
    mkdir -p $HOME/nwaku_backups/keystore0.30
    cp $HOME/nwaku-compose/keystore/keystore.json $HOME/nwaku_backups/keystore0.30/keystore.json
    rm -rf $HOME/nwaku-compose/keystore/
  fi
  
  # Remove unnecessary files and reset the repository
  rm -rf $HOME/nwaku-compose/rln_tree/ 
  cd $HOME/nwaku-compose
  git restore .
}

function update {
  # Load variables from .env into the environment
  source $HOME/nwaku-compose/.env

  # Remove the old .env
  rm -rf $HOME/nwaku-compose/.env
  cd $HOME/nwaku-compose
  git pull
  cp .env.example .env

  # Check which variable has a value
  if [ -n "$RLN_RELAY_ETH_CLIENT_ADDRESS" ]; then
    SEPOLIA_RPC="$RLN_RELAY_ETH_CLIENT_ADDRESS"
  elif [ -n "$ETH_CLIENT_ADDRESS" ]; then
    SEPOLIA_RPC="$ETH_CLIENT_ADDRESS"
  else
    echo "Check the .env file"
    exit 1
  fi

  # Update the .env file with the necessary values
  sed -i "s|RLN_RELAY_ETH_CLIENT_ADDRESS=.*|RLN_RELAY_ETH_CLIENT_ADDRESS=$SEPOLIA_RPC|" $HOME/nwaku-compose/.env
  sed -i "s|ETH_TESTNET_KEY=.*|ETH_TESTNET_KEY=$ETH_TESTNET_KEY|" $HOME/nwaku-compose/.env
  sed -i "s|RLN_RELAY_CRED_PASSWORD=.*|RLN_RELAY_CRED_PASSWORD=$RLN_RELAY_CRED_PASSWORD|" $HOME/nwaku-compose/.env
  sed -i "s|NWAKU_IMAGE=.*|NWAKU_IMAGE=harbor.status.im/wakuorg/nwaku:v0.31.0|" $HOME/nwaku-compose/.env

  # Modify docker-compose.yml with new port settings
  sed -i 's/0\.0\.0\.0:3000:3000/0.0.0.0:3004:3000/g' $HOME/nwaku-compose/docker-compose.yml
  sed -i 's/127\.0\.0\.1:4000:4000/0.0.0.0:4044:4000/g' $HOME/nwaku-compose/docker-compose.yml

  bash register_rln.sh
}


function docker_compose_up {
  docker compose -f $HOME/nwaku-compose/docker-compose.yml up -d
}

function echo_info {
  echo -e "${GREEN}To stop the Waku node: ${NORMAL}"
  echo -e "${RED}   docker-compose -f $HOME/nwaku-compose/docker-compose.yml down \n ${NORMAL}"
  echo -e "${GREEN}To start the Waku node and farmer: ${NORMAL}"
  echo -e "${RED}   docker-compose -f $HOME/nwaku-compose/docker-compose.yml up -d \n ${NORMAL}"
  echo -e "${GREEN}To restart the Waku node: ${NORMAL}"
  echo -e "${RED}   docker-compose -f $HOME/nwaku-compose/docker-compose.yml restart \n ${NORMAL}"
  echo -e "${GREEN}To check the node logs, run the command: ${NORMAL}"
  echo -e "${RED}   docker-compose -f $HOME/nwaku-compose/docker-compose.yml logs -f --tail=100 \n ${NORMAL}"
  ip_address=$(hostname -I | awk '{print $1}') >/dev/null
  echo -e "${GREEN}To check the Grafana dashboard, go to: ${NORMAL}"
  echo -e "${RED}   http://$ip_address:3004/d/yns_4vFVk/nwaku-monitoring \n ${NORMAL}"
}

# Run the functions in sequence
colors
logo
echo -e "Stopping the container, cleaning unnecessary files, and updating"
cleanup
update
echo -e "Starting docker containers for Waku"
docker_compose_up
echo_info
