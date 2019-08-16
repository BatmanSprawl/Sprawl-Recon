#!/bin/bash
########################################################################## Get Data
read -p "Enter Machine Name: " machine
mkdir $machine
cd $machine
read -p "What is the IP: " ip
echo $ip > ip.txt
########################################################################## Start Scans
echo "###############     STARTING     ###############"
echo " Machine : $machine"
echo -n " IP : " && cat ip.txt
echo -n " TCP Ports : " 
########################################################################## Get TCP
nmap -sS -p- -iL ip.txt >> ports.txt
cat ports.txt | grep tcp | cut -d / -f 1 | xargs | sed -e 's/ /,/g' >> pl.txt
cat pl.txt
echo -n " UDP Ports : "
########################################################################## Get UDP
nmap -sU -p- -iL ip.txt >> udp.txt
cat udp.txt | grep udp | cut -d / -f 1 | xargs | sed -e 's/ /,/g' >> upl.txt
cat upl.txt
########################################################################## Basic Nmap Scans
for port in $(cat pl.txt);do 
	echo "     .:TCP Start:.     "
	echo -n " Version Scan"
	nmap -sS -sV -p $port -iL ip.txt >> version.txt
	echo " . . . . . . Done"
	echo -n " Aggressive Scan"
	nmap -A -iL ip.txt >> aggro.txt
	echo ". . . . . Done"
	echo -n " OS Scan"
	nmap -O -p $port -iL ip.txt >> os.txt
	echo " . . . . . . . . Done"
	echo -n " Standard Scan"
	nmap -sC -iL ip.txt >> standscan.txt
	echo ". . . . . . Done"
	echo -n " Vulnerability Scan"
	nmap -p $port --script vuln -iL ip.txt >> vuln.txt
	echo " . . . Done";
done
########################################################################## HTTP Scans
cat ports.txt | grep http | cut -d / -f 1 >> httptmp.txt
for ps in $(cat httptmp.txt); do
	if [ $ps != "" ]
	then
		echo "      .:Http Port Found:.      "
		echo " Http Scans Starting"
		echo -n " Nmap"
		nmap --script http-enum -T 4 $ip >> http-enum-$ps.txt
		echo " . . . . . . . . . . Done" 
		echo -n " Nikto"
		nikto -h http://$ip >> nikto-basic-$ps.txt
		echo ". . . . . . . . . . Done"
		echo -n " Dirb"
		dirb http://$ip/ >> dirb-basic-$ps.txt
		echo " . . . . . . . . . . Done"
	fi;
done
########################################################################## Find SMB/SMTP 
for ps in $(cat ports.txt | grep tcp | cut -d / -f 1);do
	if [ $ps = "25" ] || [ $ps = "465" ] || [ $ps = "587" ] || [ $ps = "2525" ]
	then
		echo $ps >> smtptemp.txt
	elif [ $ps = "139" ] || [ $ps = "445" ]
	then
		echo $ps >> smbtempt.txt
	fi;
done
########################################################################## SMTP Enum
if [ -e smtptemp.txt ]
then
	cat smtptemp.txt | xargs | sed -e 's/ /,/g' >> smtpports.txt
	for smp in $(cat smtpports.txt);do
		echo "      .:SMTP Ports Found:.     "
		echo " SMTP Scans Starting"
		echo -n " Nmap"
		nmap --script smtp-enum-users -p $smtp $ip >> smtp-enum-users.txt
		nmap --script smbtp-commands -p $smtp $ip >> smtp-commands.txt
		echo " . . . . . . . . . . Done";
	done
fi
########################################################################## SMB Enum
if [ -e smbtempt.txt ]
then
	cat smbtemp.txt | xargs | sed -e 's/ /,/g' >> smbports.txt
	for smb in $(cat smbports.txt);do
		echo "      .:SMB Ports Found:.     "
		echo " SMB Scans Starting"
		echo -n " Nmap"
		nmap --script smb-enum-users -p $smb $ip >> smb-users.txt
		nmap --script smb-os-discovery -p $smb $ip >> smb-os.txt
		nmap --script smb-security-mode -p $smb $ip >> smb-security.txt
		echo " . . . . . . . . . . Done"
		echo -n " Enum4linux"
		enum4linux $ip >> enum4linux.txt
		echo " . . . . . . . Done";
	done
fi
########################################################################## Clean Up
rm pl.txt
rm smbtemp.txt
rm smtptemp.txt
echo "###############     COMPLETE     ###############"
