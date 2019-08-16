#!/bin/bash
################################################################ Progress
prog() {
	local i sp n
	sp='/-\|'
	n=${#sp}
	printf ' '
	while sleep 0.1; do
		printf "%s\b" "${sp:i++%n:1}"
	done
}
################################################################ Get Data
read -p "Enter Machine Name: " machine
mkdir $machine
cd $machine
read -p "What is the IP: " ip
echo $ip > ip.txt
################################################################ Start Scans
echo "###############     STARTING     ###############"
echo " Machine : $machine"
echo -n " IP : " && cat ip.txt
echo -n " TCP Ports : " 
################################################################ Get TCP
prog & nmap -sS -p- -iL ip.txt >> ports.txt
kill "$!" && printf "\b "
cat ports.txt | grep tcp | cut -d / -f 1 | xargs | sed -e 's/ /,/g' >> pl.txt
cat pl.txt
################################################################ Get UDP
#echo -n " UDP Ports : "
#prog & nmap -sU -iL ip.txt >> udp.txt
#kill "$!" && printf "\b "
#cat udp.txt | grep udp | cut -d / -f 1 | xargs | sed -e 's/ /,/g' >> upl.txt
#cat upl.txt
################################################################ Basic Nmap Scans
for port in $(cat pl.txt);do 
	echo "     .:TCP Start:.     "
	echo -n " Version Scan"
	prog & nmap -sS -sV -p $port -iL ip.txt >> version.txt
	kill "$!" && printf "\b . . . . . . Done"
	echo -n " Aggressive Scan"
	prog & nmap -A -iL ip.txt >> aggro.txt
	kill "$!" && printf "\b. . . . . Done"
	echo -n " OS Scan"
	prog & nmap -O -p $port -iL ip.txt >> os.txt
	kill "$!" && printf "\b . . . . . . . . Done"
	echo -n " Standard Scan"
	prog & nmap -sC -iL ip.txt >> standscan.txt
	kill "$!" && printf "\b. . . . . . Done"
	echo -n " Vulnerability Scan"
	prog & nmap -p $port --script vuln -iL ip.txt >> vuln.txt
	kill "$!" && printf "\b . . . Done";
done
################################################################ HTTP Scans
cat ports.txt | grep tcp | grep http | cut -d / -f 1 >> httptmp.txt
for ps in $(cat httptmp.txt); do
	if [ $ps != "" ]
	then
		echo "      .:Http Port Found:.      "
		echo " Http Scans Starting"
		echo -n " Nmap"
		prog & nmap --script http-enum -T 4 $ip >> http-enum-$ps.txt
		kill "$!" && printf "\b . . . . . . . . . . Done" 
		echo -n " Nikto"
		prog & nikto -h http://$ip >> nikto-basic-$ps.txt
		echo "\b. . . . . . . . . . Done"
		echo -n " Dirb"
		prog & dirb http://$ip/ >> dirb-basic-$ps.txt
		kill "$!" && printf "\b . . . . . . . . . . Done"
	fi;
done
################################################################ Find SMB/SMTP 
for ps in $(cat ports.txt | grep tcp | cut -d / -f 1);do
	if [ $ps = "25" ] || [ $ps = "465" ] || [ $ps = "587" ] || [ $ps = "2525" ]
	then
		echo $ps >> smtptemp.txt
	elif [ $ps = "139" ] || [ $ps = "445" ]
	then
		echo $ps >> smbtempt.txt
	fi;
done
################################################################ SMTP Enum
if [ -e smtptemp.txt ]
then
	cat smtptemp.txt | xargs | sed -e 's/ /,/g' >> smtpports.txt
	for smp in $(cat smtpports.txt);do
		echo "      .:SMTP Ports Found:.     "
		echo " SMTP Scans Starting"
		echo -n " Nmap"
		prog & nmap --script smtp-enum-users -p $smtp $ip >> smtp-enum-users.txt
		prog & nmap --script smbtp-commands -p $smtp $ip >> smtp-commands.txt
		kill "$!" && printf "\b\b . . . . . . . . . . Done";
	done
fi
################################################################ SMB Enum
if [ -e smbtempt.txt ]
then
	cat smbtemp.txt | xargs | sed -e 's/ /,/g' >> smbports.txt
	for smb in $(cat smbports.txt);do
		echo "      .:SMB Ports Found:.     "
		echo " SMB Scans Starting"
		echo -n " Nmap"
		prog & nmap --script smb-enum-users -p $smb $ip >> smb-users.txt
		prog & nmap --script smb-os-discovery -p $smb $ip >> smb-os.txt
		prog & nmap --script smb-security-mode -p $smb $ip >> smb-security.txt
		kill "$!" && printf "\b\b\b . . . . . . . . . . Done"
		echo -n " Enum4linux"
		prog & enum4linux $ip >> enum4linux.txt
		kill "$!" && printf "\b . . . . . . . Done";
	done
fi
################################################################ Clean Up
rm pl.txt
rm smbtemp.txt
rm smtptemp.txt
echo "###############     COMPLETE     ###############"
echo "Reminder: UDP port scan was all common ports, not all ports"
echo "Note: UDP is currently commented OUT"
