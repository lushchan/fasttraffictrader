#!/bin/bash -e

###inputfile
ifile=./f33x.txt

if [[ -z $1 ]]; then
	echo ""
	echo "Error: input parameter expected."
	echo ""
	echo "Usage:
	-l - for local install
	-s - for shared"
	echo ""
	exit
fi

if [[ ! -s $ifile ]]; then
	echo "Input file $ifile is empty. Fill it with domains"
	exit
else

cat $ifile | while read domain

do
        docroot=$(grep -r "$domain" /etc/nginx/ | grep root | awk '{print $(NF-1), $NF}'  | sed 's/root //g;s/;//g' | sed 's/^[ \t]*//g;s/[ \t]*$//g;s|/$||g' | sort -u | head -n 1)
        f33xroot=$docroot/f33x
        f3dbn=f3`echo $domain | cut -d / -f 4| sed -e 's/-/_/g'|sed 's|\.||g'`
        f3dbu=f3u`echo $domain | cut -d / -f 4|cut -c 1-13 | sed 's|-|_|g'|sed 's|\.||g'`
        f3psw=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13`
	credentials=./credentials
###some checks before destruction
	if [[ -z $docroot ]]; then
		echo "Can't find domain"
		exit
	else
###create dirs and download
	mkdir -m 777 $f33xroot
	wget -O $f33xroot/ftt2.zip http://www.ftt2.com/latest/ftt2.zip
	unzip -qq $f33xroot/ftt2.zip -d $f33xroot
	cp -Rp $f33xroot/ftt2/* $f33xroot/
	rm -rf $f33xroot/ftt2
	chmod -R 755 $f33xroot
	chown -R apache:apache $f33xroot
	rm $f33xroot/ftt2.zip

###local
if [ '-l' = "$1" ]; then

	echo "local install"
	mysql -e "CREATE DATABASE ${f3dbn} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	mysql -e "CREATE USER ${f3dbu}@localhost"
	mysql -e "GRANT ALL PRIVILEGES ON ${f3dbn}.* TO '${f3dbu}'@'localhost' IDENTIFIED BY '${f3psw}';"
	mysql -e "FLUSH PRIVILEGES;"
	echo -e "go to the next URL to finish installation http://$domain/f33x/install \n Use the following credentials: \n dbHost: localhost \n dbName $f3dbn \n dbUser: $f3dbu \n dbPassword: $f3psw \n " | tee -a $credentials
fi

###shared
if [ '-s' = "$1" ]; then 
	echo "shared install"
	read -p "enter a user name of shared database(without @localhost) " f3shared
	mysql -e "CREATE DATABASE ${f3dbn} /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	mysql -e "GRANT ALL PRIVILEGES ON ${f3dbn}.* TO '${f3shared}'@'localhost';"
	mysql -e "FLUSH PRIVILEGES;"
	echo -e "go to the next URL to finish installation http://$domain/f33x/install"
	echo "Use the following credentials \n dbName $f3dbn \n dbUser of shared database: $f3shared \n" | tee -a $credentials
fi
	fi
done
fi
cat /dev/null > $ifile
