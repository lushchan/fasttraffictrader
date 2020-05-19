#!/bin/bash -e
#logging
##timestampformat
tstamp=$(date +%m/%d/%Y-%H:%M:%S)
##credentials
creds=./creds.txt
#inputfile
ifile=./f33x.txt
if [[ -z $1 ]]; then
	echo ""
	echo "Error: input parameter expected."
	echo ""
	echo "Usage:
	-l - for local install. Example bash f33x.sh -l
	-s shareduser - for shared. Example bash f33x.sh -s nameofshareduser"
	echo ""
	exit
fi

if [ '-s' = "$1" ] && [[ -z $2 ]]; then 
	echo "fail"
	exit
fi

if [[ ! -s $ifile ]]; then
	echo "Input file $ifile is empty. Fill it with domains"
	exit
else

wget http://www.ftt2.com/latest/ftt2.zip
unzip ftt2.zip

cat $ifile | while read domain

do
        docroot=$(grep -r "$domain" /etc/nginx/ | grep root | awk '{print $(NF-1), $NF}'  | sed 's/root //g;s/;//g' | sed 's/^[ \t]*//g;s/[ \t]*$//g;s|/$||g' | sort -u | head -n 1)
        f33xroot=$docroot/f33x
        f3dbn=f3`echo $domain | cut -d / -f 4| sed -e 's/-/_/g'|sed 's|\.||g'`
        f3dbu=f3u`echo $domain | cut -d / -f 4|cut -c 1-13 | sed 's|-|_|g'|sed 's|\.||g'`
        f3psw=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13`
###some checks before destruction
	if [[ -z $docroot ]]; then
		echo "Can't find domain"
		exit
	else
###create dirs and download
	cp -Rp ftt2 $f33xroot
	chmod -R 755 $f33xroot
	chmod 777 $f33xroot
	chown -R apache:apache $f33xroot

###local
if [ '-l' = "$1" ]; then
	echo "local install"
	mysql -e "CREATE DATABASE ${f3dbn} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	mysql -e "CREATE USER ${f3dbu}@localhost  IDENTIFIED BY '${f3psw}'"
	mysql -e "GRANT ALL PRIVILEGES ON ${f3dbn}.* TO '${f3dbu}'@'localhost';"
	mysql -e "FLUSH PRIVILEGES;"
	echo -e "[$tstamp] \n go to the next URL to finish installation http://$domain/f33x/install \n Use the following credentials: \n dbHost: localhost \n dbName $f3dbn \n dbUser: $f3dbu \n dbPassword: $f3psw \n " | tee -a $creds
fi

###shared
if [ '-s' = "$1" ]; then
	echo "shared install"
	mysql -e "CREATE DATABASE ${f3dbn} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	mysql -e "GRANT ALL PRIVILEGES ON ${f3dbn}.* TO '${2}'@'localhost';"
	mysql -e "FLUSH PRIVILEGES;"
	echo -e "[$tstamp] \n go to the next URL to finish installation http://$domain/f33x/install \n Use the following credentials: \n dbName $f3dbn \n dbUser of shared database: '$2'@'localhost' \n" | tee -a $creds
fi
fi
done
fi
cat /dev/null > $ifile
rm ftt2.zip
rm -rf ./ftt2
exit
