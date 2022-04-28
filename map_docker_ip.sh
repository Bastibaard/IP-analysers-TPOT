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

case "$1" in
	"-name")
	DOCKER_NAME="$2"
	;;
	"-ip")
	DOCKER_IP="$2"
	;;
	"-h" | "--help")
	fuHELP
	;;
	*)
	fuHELP
	exit 1
	;;
esac

if [ $1 = "-name" ]; then
	NETWORK_ID=$(sudo docker network ls | grep $DOCKER_NAME |cut -d " " -f 1)
	if ! [[ $NETWORK_ID = "" ]]; then
		NETWORK_IP=$(ip addr | grep global | grep $NETWORK_ID | awk '{print $2}')
	#	NETWORK_IP=$(ip addr | grep global | grep $NETWORK_ID | tr -s ' ' | cut -d ' ' -f 3)
		echo -e "Docker Name: \t IP-address"
		echo -e "$DOCKER_NAME \t $NETWORK_IP"
		exit 0
	else
		echo "No results found"
		exit 0
	fi

elif [ $1 = "-ip" ]; then
	DOCKER_ID=$(ip addr | grep global | grep $DOCKER_IP | awk '{print $7}' | cut -c 4-)
	if ! [[ $DOCKER_ID = "" ]]; then
		DOCKER_NAME=$(sudo docker network ls | grep $DOCKER_ID | awk '{print $2}' | cut -c 5-)
		echo -e "Docker Name: \t IP-address"
		echo -e "$DOCKER_NAME \t $DOCKER_IP"
		exit 0
	else
		echo "No results found"
		exit 0
	fi
fi
