# TPOT-scripts

This script is made as a part of an extension for the extensive [T-POT software honeypot](https://github.com/telekom-security/tpotce). As some people might know, this honeypot application comes preshipped with a lot of handy-dandy scripts. However I missed one which suited MY needs and fit into the implementation of MY organization. The functionalities these scripts offer may or may not be suited for your organization or hold no value.

## top_ips_by_count.sh

If you are ever stuck on the syntax used in this script, you can go ahead and use 
> `sudo ./top_ips_by_count.sh -h` or `sudo ./top_ips_by_count.sh --help`:

```bash
This script gives a list of the top 100 source IP-addresses (if present) that were captured based on their count. 
Filters are given below. Addresses which can be mapped to internal honeypots will be listed as such. 
Default date is set to one month ago.

Usage:
./top_ips_by_count.sh [TYPE] -d [DATE]

Examples (you should be running this script as root):
./top_ips_by_count.sh private -d '2202-03'       Returns all private addresses listed in the top 100 listed source IPs.
./top_ips_by_count.sh public -d '2202-03'        Returns all public addresses listed in the top 100 listed source IPs.
./top_ips_by_count.sh honeypots -d '2202-03'     Returns all honeypots listed in the top 100 listed source IPs.
./top_ips_by_count.sh nohoneypots -d '2202-03'   Filters out all honeypots from the top 100 listed source IPs.
./top_ips_by_count.sh all -d '2202-03'           Returns all addresses listed in the top 100 listed source IPs.

To find out what containers are currently running on your system, you can verify with 'sudo docker ps -a
Base script by github.com/telekom-security/tpotce and edited by @Bastibaard
```

---

### Where does the data come from?

The data given tot his script can be found via Elasticsearch via a custom query which was already implemented by a Kibana dashboard. The picture on the right indicates the top 10 Attacker Source IPs. 

I noticed a lot of private addresses in this list so I wanted a quick and easy way to find out which of these are running honeypots on the system and thus which systems reported the most activity to the honeypot without the need of kibana dashboards.

The script started as a small adaptation of the existing [“mytopips.sh”](https://github.com/telekom-security/tpotce/blob/master/bin/mytopips.sh) script, which based its data on how often an ip-address was found in any of the logs sorted from most counts to lowest counts. My other script “top_ips_by_type.sh” uses this same dataset so you should find way more ip-addresses (private and public) via that script.

In this case however I chose to take the information below. In order to get this data, I sent a GET request via cURL to my elasticsearch cluster. Feel free to fabricate your own, however I chose to implement the exact query used to get the results below with one change: I took the top **100** results instead of the top 10 only.

![attacker_source_ip](https://user-images.githubusercontent.com/92089291/165717337-ed65b2fb-62b1-4d67-8c4c-79a8c9daf94e.png)

> *Click the three dots in the top right corner of the visualisation. In the expanded view, click the View: Data in the top right corner and click on requests. In this final view, you can go to the request tab et voilà. Simply copy this body and paste it between the single quotes*
---

### Example usage of the command:

![script_example_output](https://user-images.githubusercontent.com/92089291/165716782-f13d88fd-45ce-49bc-bcb0-e109eb913cb4.png)

The script lists top 100 attacker source IPs together with a green note if they are running honeypots on the system. You also have the option to filter these results out or only give these results. There is also the possibility to filter on private addresses or public only (only works for IPv4 addresses at the time of writing this readme).

