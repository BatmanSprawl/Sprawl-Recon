#!/bin/bash
read -p "Enter Machine Name: " machine
mkdir $machine
cd $machine
read -p "What is the IP: " ip
echo $ip > ip.txt
echo "###############     STARTING     ###############"
echo " Machine : $machine"
echo -n " IP : " && cat ip.txt
echo -n " Ports : " 
nmap -sS -p- -iL ip.txt >> ports.txt
cat ports.txt | grep tcp | cut -d / -f 1 | xargs | sed -e 's/ /,/g' >> pl.txt
cat pl.txt
echo -n " Version Scan"
for port in $(cat pl.txt);do nmap -sS -sV -p $port -iL ip.txt >> version.txt;done
echo " . . . . . . Done"
echo -n " Aggressive Scan"
nmap -A -iL ip.txt >> aggro.txt
echo ". . . . . Done"
echo -n " OS Scan"
for port in $(cat pl.txt);do nmap -O -p $port -iL ip.txt >> os.txt;done
echo ". . . . . . . . . Done"
echo -n " Standard Scan"
nmap -sC -iL ip.txt >> standscan.txt
echo ". . . . . . Done"
echo -n " Vulnerability Scan"
for port in $(cat pl.txt);do nmap -p $port --script vuln -iL ip.txt >> vuln.txt;done
echo " . . . Done"
echo "###############     COMPLETE     ###############"
