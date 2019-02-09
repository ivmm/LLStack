#!/bin/bash
#
#
# CentOS 7 LLStack
# Author: ivmm <cjwbbs@gmail.com>
# Home: https://www.llstack.com
# Blog: https://www.mf8.biz
#
# * LiteSpeed Enterprise Web Server
# * MySQL 5.5/5.6/5.7/8.0(MariaDB 5.5/10.0/10.1/10.2/10.3)
# * PHP 5.4/5.5/5.6/7.0/7.1/7.2/7.3
# * phpMyAdmin(Adminer)
#
# https://github.com/ivmm/LLStack/
#
# Usage: sh vhost.sh
#

# check root
[ "$(id -g)" != '0' ] && die 'Script must be run as root.'

clear
echo "====================================================================="
echo -e "\033[32mLLStack for CentOS/RedHat 7\033[0m"
echo "====================================================================="
echo -e "\033[32mA tool to auto-compile & install LiteSpeed+MySQL(MariaDB)+PHP on Linux\033[0m"
echo ""
echo -e "\033[32mFor more information please visit https://www.llstack.com/\033[0m"
echo "====================================================================="

#Domain name
domain="mf8.biz"
echo "Please input domain:"
read -p "(Default domain: mf8.biz):" domain
if [ "$domain" = "" ]; then
  domain="mf8.biz"
fi

if [ ! -f "//usr/local/lsws/conf/vhosts/$domain.xml" ]; then
  echo "==========================="
  echo "domain=$domain"
  echo "===========================" 
else
  echo "==========================="
  echo "$domain is exist!"
  echo "==========================="  
  exit 0
fi

#WebMaster's Email
webmasteremail="admin@mf8.biz"
echo "Please input The WebMaster's Email:"
read -p "(Example: admin@mf8.biz):" webmasteremail
if [ "$webmasteremail" = "" ]; then
  webmasteremail="admin@mf8.biz"
fi

#LSPHP Version
Llsphpversion=$(cat /usr/share/lsphp-default-version)
echo "Please input The PHP Version(If you have installed multiple versions of PHP): "
read -p "PHP Version,Example: lsphp71,lsphp70 or lsphp56: " -r -e -i "${Llsphpversion}" lsphpversion
if [ "$lsphpversion" = "" ]; then
  lsphpversion=$(cat /usr/share/lsphp-default-version)
fi


#More domain name
read -p "Do you want to add more domain name? (y/n)" add_more_domainame
    
if [ "$add_more_domainame" = 'y' ] || [ "$add_more_domainame" = 'Y' ]; then
  echo "Please input domain name,example(www.mf8.biz,statics.mf8.biz,imgs.mf8.biz)"
  read -p "Please use \",\" between each domain: " moredomain
  echo "==========================="
  echo domain list="$moredomain"
  echo "==========================="
  moredomainame=" $moredomain"
fi

#Enable SSL
read -p "Do you want to enable HTTPS? (y/n)" enablessl
    
if [ "$enablessl" = 'y' ] || [ "$enablessl" = 'Y' ]; then
  echo "Please input the Private Key File Path"
  read -p "Example:/home/demo/ssl/www.mf8.biz.key " privatekeypath
  echo "Please input the Certificate File Path"
  read -p "Example:/home/demo/ssl/www.mf8.biz.crt " certificatepath
  read -p "Do you want to enable HTTP/3(QUIC)? (y/n) " enablequic
  echo "==========================="
  echo Private Key File Path="$privatekeypath"
  echo Certificate File Path="$certificatepath"
  echo "==========================="
  chown lsadm:lsadm $privatekeypath
  chown lsadm:lsadm $certificatepath
fi
    
get_char() {
  SAVEDSTTY=`stty -g`
  stty -echo
  stty cbreak
  dd if=/dev/tty bs=1 count=1 2> /dev/null
  stty -raw
  stty echo
  stty $SAVEDSTTY
}

echo ""
echo "Press any key to start or CTRL+C to cancel."
char=`get_char`
    
#Mkdir for vhost
mkdir -p /home/$domain/{public_html,logs,ssl,cgi-bin,cache}
chown -R nobody:nobody /home/$domain/public_html

#add httpd conf Virtual host
cp -f /usr/local/lsws/conf/httpd_config.xml /usr/local/lsws/conf/httpd_config.xml.bak
v1="<virtualHost>"
v2="<name>$domain<\/name>"
v3="<vhRoot>\/home\/$domain<\/vhRoot>"
v4="<configFile>\$SERVER_ROOT\/conf\/vhosts\/$domain.xml<\/configFile>"
v5="<allowSymbolLink>1<\/allowSymbolLink>"
v6="<enableScript>1<\/enableScript>"
v7="<restrained>0<\/restrained>"
v8="<setUIDMode>2<\/setUIDMode>"
v9="<chrootMode>0<\/chrootMode>"
v10="<\/virtualHost>"
vend="<\/virtualHostList>"
sed -i 's/'$vend'/'$v1'\n'$v2'\n'$v3'\n'$v4'\n'$v5'\n'$v6'\n'$v7'\n'$v8'\n'$v9'\n'$v10'\n&/' /usr/local/lsws/conf/httpd_config.xml

if [ "$enablessl" = 'y' ] || [ "$enablessl" = 'Y' ]; then

#add httpd conf listen (https)
l1="<vhostMap>"
l2="<vhost>$domain<\/vhost>"
l3="<domain>$domain,$moredomain<\/domain>"
l4="<\/vhostMap>"
lend="<\/vhostMapList>"
sed -i 's/'$lend'/'$l1'\n'$l2'\n'$l3'\n'$l4'\n&/' /usr/local/lsws/conf/httpd_config.xml

  if [ "$add_more_domainame" = 'y' ] || [ "$add_more_domainame" = 'Y' ]; then
    l1="<vhostMap>"
    l2="<vhost>$domain<\/vhost>"
    l3="<domain>$domain,$moredomain<\/domain>"
    l4="<\/vhostMap>"
    lend="<\/vhostMapList>"
    sed -i 's/'$lend'/'$l1'\n'$l2'\n'$l3'\n'$l4'\n&/' /usr/local/lsws/conf/httpd_config.xml
  else
    l1="<vhostMap>"
    l2="<vhost>$domain<\/vhost>"
    l3="<domain>$domain<\/domain>"
    l4="<\/vhostMap>"
    lend="<\/vhostMapList>"
    sed -i 's/'$lend'/'$l1'\n'$l2'\n'$l3'\n'$l4'\n&/' /usr/local/lsws/conf/httpd_config.xml
  fi

#add vhost conf (https)
cat >>/usr/local/lsws/conf/vhosts/$domain.xml<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<virtualHostConfig>
  <docRoot>/home/$domain/public_html</docRoot>
  <adminEmails>$webmasteremail</adminEmails>
  <enableGzip>1</enableGzip>
  <logging>
    <log>
      <useServer>1</useServer>
      <fileName>/home/$domain/logs/$domain_errors.log</fileName>
      <logLevel>ERROR</logLevel>
      <rollingSize>100M</rollingSize>
    </log>
    <accessLog>
      <useServer>0</useServer>
      <fileName>/home/$domain/logs/$domain.access.log</fileName>
      <logHeaders>3</logHeaders>
      <rollingSize>100M</rollingSize>
      <keepDays>30</keepDays>
      <compressArchive>1</compressArchive>
    </accessLog>
  </logging>
  <index>
    <useServer>0</useServer>
    <indexFiles>index.html, index.htm, index.php</indexFiles>
  </index>
  <scriptHandlerList>
    <scriptHandler>
      <suffix>php</suffix>
      <type>lsapi</type>
      <handler>$lsphpversion</handler>
    </scriptHandler>
  </scriptHandlerList>
  <expires>
    <enableExpires>1</enableExpires>
  </expires>
  <cache>
    <storage>
      <cacheStorePath>/home/$domain/cache</cacheStorePath>
      <litemage>0</litemage>
    </storage>
  </cache>
  <extProcessorList>
    <extProcessor>
      <type>lsapi</type>
      <name>$lsphpversion</name>
      <address>uds://tmp/lshttpd/$domain-$lsphpversion.sock</address>
      <maxConns>35</maxConns>
      <env>PHP_LSAPI_MAX_REQUESTS=5000</env>
      <env>PHP_LSAPI_CHILDREN=35</env>
      <initTimeout>180</initTimeout>
      <retryTimeout>0</retryTimeout>
      <persistConn>1</persistConn>
      <pcKeepAliveTimeout>30</pcKeepAliveTimeout>
      <respBuffer>0</respBuffer>
      <autoStart>1</autoStart>
      <path>/usr/bin/$lsphpversion</path>
      <backlog>100</backlog>
      <instances>1</instances>
      <extMaxIdleTime>10</extMaxIdleTime>
      <priority>0</priority>
      <memSoftLimit>1024M</memSoftLimit>
      <memHardLimit>1024M</memHardLimit>
      <procSoftLimit>400</procSoftLimit>
      <procHardLimit>500</procHardLimit>
    </extProcessor>
  </extProcessorList>
  <contextList>
    <context>
      <type>cgi</type>
      <uri>/cgi-bin/</uri>
      <location>/home/$domain/cgi-bin/</location>
      <accessControl>
      </accessControl>
      <rewrite>
      </rewrite>
      <cachePolicy>
      </cachePolicy>
      <addDefaultCharset>off</addDefaultCharset>
    </context>
  </contextList>
  <vhssl>
    <keyFile>$privatekeypath</keyFile>
    <certFile>$certificatepath</certFile>
    <certChain>1</certChain>
    <renegProtection>1</renegProtection>
    <sslSessionCache>1</sslSessionCache>
    <sslSessionTickets>1</sslSessionTickets>
    <enableSpdy>4</enableSpdy>
    <enableQuic>0</enableQuic>
  </vhssl>
</virtualHostConfig>
EOF

    if [ "$enablequic" = 'y' ] || [ "$enablequic" = 'Y' ]; then
      sed -i "s@<enableQuic>0</enableQuic>@<enableQuic>1</enableQuic>@g" /usr/local/lsws/conf/vhosts/$domain.xml
    fi

else 

#add httpd conf listen(http)
l1="<vhostMap>"
l2="<vhost>$domain<\/vhost>"
l3="<domain>$domain,$moredomain<\/domain>"
l4="<\/vhostMap>"
lend="<\/vhostMapList><!--HTTP-->"
sed -i 's/'$lend'/'$l1'\n'$l2'\n'$l3'\n'$l4'\n&/' /usr/local/lsws/conf/httpd_config.xml

if [ "$add_more_domainame" = 'y' ] || [ "$add_more_domainame" = 'Y' ]; then
l1="<vhostMap>"
l2="<vhost>$domain<\/vhost>"
l3="<domain>$domain,$moredomain<\/domain>"
l4="<\/vhostMap>"
lend="<\/vhostMapList><!--HTTP-->"
sed -i 's/'$lend'/'$l1'\n'$l2'\n'$l3'\n'$l4'\n&/' /usr/local/lsws/conf/httpd_config.xml
else
l1="<vhostMap>"
l2="<vhost>$domain<\/vhost>"
l3="<domain>$domain<\/domain>"
l4="<\/vhostMap>"
lend="<\/vhostMapList><!--HTTP-->"
sed -i 's/'$lend'/'$l1'\n'$l2'\n'$l3'\n'$l4'\n&/' /usr/local/lsws/conf/httpd_config.xml
fi

#add vhost conf (http)
cat >>/usr/local/lsws/conf/vhosts/$domain.xml<<EOF
<?xml version="1.0" encoding="UTF-8"?>
<virtualHostConfig>
  <docRoot>/home/$domain/public_html</docRoot>
  <adminEmails>$webmasteremail</adminEmails>
  <enableGzip>1</enableGzip>
  <logging>
    <log>
      <useServer>1</useServer>
      <fileName>/home/$domain/logs/$domain_errors.log</fileName>
      <logLevel>ERROR</logLevel>
      <rollingSize>100M</rollingSize>
    </log>
    <accessLog>
      <useServer>0</useServer>
      <fileName>/home/$domain/logs/$domain.access.log</fileName>
      <logHeaders>3</logHeaders>
      <rollingSize>100M</rollingSize>
      <keepDays>30</keepDays>
      <compressArchive>1</compressArchive>
    </accessLog>
  </logging>
  <index>
    <useServer>0</useServer>
    <indexFiles>index.html, index.htm, index.php</indexFiles>
  </index>
  <scriptHandlerList>
    <scriptHandler>
      <suffix>php</suffix>
      <type>lsapi</type>
      <handler>$lsphpversion</handler>
    </scriptHandler>
  </scriptHandlerList>
  <expires>
    <enableExpires>1</enableExpires>
  </expires>
  <cache>
    <storage>
      <cacheStorePath>/home/$domain/cache</cacheStorePath>
      <litemage>0</litemage>
    </storage>
  </cache>
  <extProcessorList>
    <extProcessor>
      <type>lsapi</type>
      <name>$lsphpversion</name>
      <address>uds://tmp/lshttpd/$domain-$lsphpversion.sock</address>
      <maxConns>35</maxConns>
      <env>PHP_LSAPI_MAX_REQUESTS=5000</env>
      <env>PHP_LSAPI_CHILDREN=35</env>
      <initTimeout>180</initTimeout>
      <retryTimeout>0</retryTimeout>
      <persistConn>1</persistConn>
      <pcKeepAliveTimeout>30</pcKeepAliveTimeout>
      <respBuffer>0</respBuffer>
      <autoStart>1</autoStart>
      <path>/usr/bin/$lsphpversion</path>
      <backlog>100</backlog>
      <instances>1</instances>
      <extMaxIdleTime>10</extMaxIdleTime>
      <priority>0</priority>
      <memSoftLimit>1024M</memSoftLimit>
      <memHardLimit>1024M</memHardLimit>
      <procSoftLimit>400</procSoftLimit>
      <procHardLimit>500</procHardLimit>
    </extProcessor>
  </extProcessorList>
  <contextList>
    <context>
      <type>cgi</type>
      <uri>/cgi-bin/</uri>
      <location>/home/$domain/cgi-bin/</location>
      <accessControl>
      </accessControl>
      <rewrite>
      </rewrite>
      <cachePolicy>
      </cachePolicy>
      <addDefaultCharset>off</addDefaultCharset>
    </context>
  </contextList>
</virtualHostConfig>
EOF

fi

chown -R lsadm:lsadm /usr/local/lsws/conf/vhosts/$domain.xml


service lsws restart

echo "========================================================================="
echo "The Virtual host has been created"
echo "The path of the Virtual host is /home/$domain/"
echo "Please upload the web files into /home/$domain/public_html"
echo "========================================================================="
