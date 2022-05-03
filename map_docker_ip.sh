#!/bin/bash

# Author: @Bastibaard on Github
# This script was made by Thomas Van Nevel and is based on the scripting functionalities of the T-POT suite.

# Run as root only.
myWHOAMI=$(whoami)
if [ "$myWHOAMI" != "root" ]
  then
    echo "Need to run as root ..."
    exit
fi

function fuHELP(){
	echo -e "This script should help map Docker container names to their IP and vice versa.\n"
	echo -e "Usage (you should be running this script as root):\n"
	echo -e "./map_docker_ip.sh -name [DOCKER_NAME] \t\t Returns the IP address of the give Docker container"
	echo -e "./map_docker_ip.sh -ip [IP_ADDRESS] \t\t Returns the Docker name of the given IP"
	echo -e "./map_docker_ip.sh -h or --help \t\t Prints this help \n"
	echo -e "Example: \n"
	echo -e "./map_docker_ip.sh -ip 172.28.0.1"
	echo -e "./map_docker_ip.sh -name dionaea \n"
	echo -e "To find out what containers are currently running on your system, you can verify with 'sudo docker ps -a'"
}

function fuDOCKNAMETOIP(){
	# Gets argument $DOCKER_NAME
	DOCKER_NAME=$1
	NETWORK_ID=$(sudo docker network ls | grep $DOCKER_NAME | awk '{print $1}')
	NETWORK_NAME=$(sudo docker network ls | grep $DOCKER_NAME | awk '{print $2}')

	if ! [[ $NETWORK_ID = "" ]]; then
		DOCKER_GATE=$(ip addr | grep global | grep $NETWORK_ID | awk '{print $2}')
		IP_ADDR=$(sudo docker inspect -f "{{ .NetworkSettings.Networks.$NETWORK_NAME.IPAddress }}" $DOCKER_NAME)
		echo -e "Docker Name: \t Gateway: \t IP-address"
		echo -e "$DOCKER_NAME \t ${DOCKER_GATE::-3} \t $IP_ADDR"
		exit 0
	else
		echo "No results found."
		exit 0
	fi
}

function fuDOCKNAMEFROMIP(){
	# Gets argument $DOCKER_IP
	FULL_IP=$1
	PARTIAL_IP=$(echo $1 | tr -d " " | cut -d "." -f1,2,3)
	BRIDGE_ID=$(ip addr | grep global | grep $PARTIAL_IP | awk '{print $7}' | cut -c 4-)
	NETWORK_NAME=$(sudo docker network ls | grep $BRIDGE_ID | awk '{print $2}')
	DOCKER_NAME=$(sudo docker network ls | grep $BRIDGE_ID | awk '{print $2}' | awk -F '[_*_]' '{print $2}')

	if ! [[ $NETWORK_NAME = "" ]];then
		set -e
		IP_ADDR=$(sudo docker inspect -f "{{ .NetworkSettings.Networks.$NETWORK_NAME.IPAddress }}" $DOCKER_NAME)
		GATEWAY=$(sudo docker inspect -f "{{ .NetworkSettings.Networks.$NETWORK_NAME.Gateway }}" $DOCKER_NAME)
	fi

	if [[ $GATEWAY = $FULL_IP ]];then
		echo -e "Docker Name: \t Gateway: \t IP-address"
		echo -e "$DOCKER_NAME \t $GATEWAY \t $IP_ADDR"
	elif [[ $IP_ADDR = $FULL_IP  ]];then
		echo -e "Docker Name: \t Gateway: \t IP-address"
		echo -e "$DOCKER_NAME \t $GATEWAY \t $FULL_IP"
	else
		echo "No results found."
		exit 0
	fi
}

case "$1" in
	"-name")
	fuDOCKNAMETOIP "$2"
	;;
	"-ip")
	fuDOCKNAMEFROMIP "$2"
	;;
	"-h" | "--help")
	fuHELP
	;;
	*)
	fuHELP
	exit 1
	;;
esac
