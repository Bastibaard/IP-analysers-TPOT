#!/bin/bash

# Author: @Bastibaard on Github
# This script was made by Thomas Van Nevel and is based on the scripting functionalities of the T-POT suite.

SCRIPTNAME=$0
# Run as root only.
myWHOAMI=$(whoami)
if [ "$myWHOAMI" != "root" ]
  then
    echo "Need to run as root ..."
    exit
fi

# Make sure ES is available
myES="http://127.0.0.1:64298/"
myESSTATUS=$(curl -s -XGET ''$myES'_cluster/health' | jq '.' | grep -c green)
termColor=$(tput setaf 2)
reset=$(tput sgr0)
QUERY_DATE="now-1M/M"

function fuMYTOPIPS() {
curl -s -XGET $myES"_search" -H 'Content-Type: application/json' -d'
{
  "aggs": {
    "ips": {
      "terms": {
        "field": "src_ip.keyword",
        "order": {
          "_count": "desc"
        },
        "size": 100
      }
    }
  },
  "size": 0,
  "fields": [
    {
      "field": "@timestamp",
      "format": "date_time"
    },
    {
      "field": "flow.start",
      "format": "date_time"
    },
    {
      "field": "time_iso8601",
      "format": "date_time"
    },
    {
      "field": "timestamp",
      "format": "date_time"
    },
    {
      "field": "tls.notafter",
      "format": "date_time"
    },
    {
      "field": "tls.notbefore",
      "format": "date_time"
    }
  ],
  "script_fields": {},
  "stored_fields": [
    "*"
  ],
  "runtime_mappings": {},
  "_source": {
    "excludes": []
  },
  "query": {
    "bool": {
      "must": [
        {
          "query_string": {
            "query": "*",
            "analyze_wildcard": true,
            "time_zone": "Europe/Brussels"
          }
        },
        {
          "query_string": {
            "query": "type:\"Adbhoney\" OR type:\"Ciscoasa\" OR type:\"CitrixHoneypot\" OR type:\"ConPot\" OR type:\"Cowrie\" OR type:\"Ddospot\" OR type:\"Dicompot\" OR type:\"Dionaea\" OR type:\"ElasticPot\" OR type:\"Endlessh\" OR type:\"Glutton\" OR type:\"Hellpot\" OR type:\"Heralding\" OR type:\"Honeypy\" OR type:\"Honeysap\" OR type:\"Honeytrap\" OR type:\"Honeypots\" OR type: \"Log4pot\" OR type:\"Ipphoney\" OR type:\"Mailoney\" OR type:\"Medpot\" OR type:\"Rdpy\" OR type:\"Redishoneypot\" OR type:\"Tanner\"",
            "analyze_wildcard": true,
            "time_zone": "Europe/Brussels"
          }
        }
      ],
      "filter": [
        {
          "range": {
            "@timestamp": {
               	"gte": "'"$1"'",
		"lte": "now/d"
            }
          }
        }
      ],
      "should": [],
      "must_not": []
    }
  }
}'
}

function fuHELP(){
        echo -e "This script gives a list of the top 100 source IP-addresses (if present) that were captured. Filters are given below. Addresses which can be mapped to internal honeypots will be listed as such. Default date is set to one month ago.\n"
        echo -e "Usage:"
	echo -e "$SCRIPTNAME [TYPE] -d [DATE]\n"
	echo -e "Examples (you should be running this script as root):\n"
        echo -e "$SCRIPTNAME private -d '2022-03'\t Returns all private addresses listed in the top 100 listed source IPs." 
        echo -e "$SCRIPTNAME public -d '2022-03'\t Returns all public addresses listed in the top 100 listed source IPs." 
        echo -e "$SCRIPTNAME honeypots -d '2022-03'\t Returns all honeypots listed in the top 100 listed source IPs." 
        echo -e "$SCRIPTNAME nohoneypots -d '2022-03'\t Filters out all honeypots from the top 100 listed source IPs." 
        echo -e "$SCRIPTNAME all -d '2022-03'\t\t Returns all addresses listed in the top 100 listed source IPs. \n" 
	echo -e "To find out what containers are currently running on your system, you can verify with 'sudo docker ps -a"
	echo -e "Base script by github.com/telekom-security/tpotce and edited by @Bastibaard"
}

function fuMYTOPPUBORPRIVIPS {
echo "### Parsing $addrTYPE IPs from top 100 source IP addresses in ES"
# TODO: expand so you can see how many hits per item there are
# DOC_COUNT=$(fuMYTOPIPS | jq '.aggregations.ips.buckets[].doc_count' | tr -d '"')
echo -e "The chose query date is: $QUERY_DATE \n"
echo -e "# \t IP-addr \t ishoneypot"
IPS=$(fuMYTOPIPS $QUERY_DATE | jq '.aggregations.ips.buckets[].key' | tr -d '"')
IPNUM=1
for IP in $IPS
do
	classBPrivate2=$(echo $IP | cut -d "." -f 2)

	DOCKER_CONTAINER=$(fuISHONEYPOT $IP)
	termColor=$($(fuCOLORHONEYPOTS $DOCKER_CONTAINER))

	#Special case for class B private range 172.16.X.X to 172.32.x.x
	if [[ $addrTYPE = "private" ]] && [[ $IP =~ ^(172) ]] && ((16 <= $classBPrivate2 < 32)); then
		echo -e "$IPNUM.\t $IP \t ${termColor}$DOCKER_CONTAINER${reset}"
	fi

	if [[ $addrTYPE = "private" ]]; then
		if [[ $IP =~ ^(127|10|192) ]]; then
			echo -e "$IPNUM.\t $IP \t ${termColor}$DOCKER_CONTAINER${reset}"
		fi
	elif [[ $addrTYPE = "public" ]]; then
		if ! [[ $IP =~ ^(fe|127|0|172|10|192) ]]; then
			echo "$IPNUM.\t $IP"
		fi
	elif [[ $addrTYPE = "all" ]]; then
		echo -e "$IPNUM.\t $IP \t ${termColor}$DOCKER_CONTAINER${reset}"
	elif [[ $addrTYPE = "honeypots" ]] && ! [[ $DOCKER_CONTAINER = "N/A" ]]; then
		if ! [[ $DOCKER_CONTAINER = "" ]]; then
			echo -e "$IPNUM.\t $IP \t ${termColor}$DOCKER_CONTAINER${reset}"
		fi
	elif [[ $addrTYPE = "nohoneypots" ]] && [[ $DOCKER_CONTAINER = "N/A" ]] || [[ $DOCKER_CONTAINER = "" ]]; then
		echo -e "$IPNUM.\t $IP"
	fi
	((IPNUM=IPNUM+1))
done
}

function fuCOLORHONEYPOTS()
{
	if [[ $1 = "N/A" ]];then
		echo "tput setaf 7"
	else
		echo "tput setaf 2"
	fi
}


function fuISHONEYPOT()
{

DOCKER_IP="$1"

DOCKER_ID=$(ip addr | grep global | grep $DOCKER_IP | awk '{print $7}' | cut -c 4-)
if ! [[ $DOCKER_ID = "" ]]; then
	DOCKER_NAME=$(sudo docker network ls | grep $DOCKER_ID | awk '{print $2}' | cut -c 5-)
	echo $DOCKER_NAME
        exit 0
else
        echo "N/A"
        exit 0

fi
}

#main


case "$1" in
        "private" | "public" | "all" | "honeypots" | "nohoneypots")
        addrTYPE="$1"
        ;;
        "-h" | "--help")
        fuHELP
        ;;
        *)
        fuHELP
        exit 1
        ;;
esac


case "$2" in
	"-d" | "--date")
	QUERY_DATE=$3
	;;
	"-h" | "--help")
	fuHELP
	exit 0
	;;
	"")
	QUERY_DATE="now-1M/M"
	;;
esac



if [ $# -gt 0 ]; then
	if ! [ "$myESSTATUS" = "1" ]
	  then
	    echo "### Elasticsearch is not available, try starting via 'systemctl start elk'."
	    exit 1
	  else
	    echo "### Elasticsearch is available, now continuing."
	    echo
	fi
	fuMYTOPPUBORPRIVIPS
else
	fuHELP
	exit 1
fi
