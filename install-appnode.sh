#!/bin/bash
#
#
# CentOS 7 LLStack
# Author: ivmm <cjwbbs@gmail.com>
# Home: https://www.llstack.com
# Blog: https://www.mf8.biz
#
# * LiteSpeed Enterprise Web Server
# * Support with APPNode
# * MySQL 5.5/5.6/5.7(MariaDB 5.5/10.0/10.1/10.2)
# * PHP 5.4/5.5/5.6/7.0/7.1/7.2/7.3
# * phpMyAdmin(Adminer)
#
# https://github.com/ivmm/LLStack/
#
# Usage: sh install-appnode.sh
#

# check root
[ "$(id -g)" != '0' ] && die 'Script must be run as root.'

# declare variables
envType='master'
ipAddress=`curl -s -4 https://api.ip.sb/ip`
mysqlPWD=$(echo -n ${RANDOM} | md5sum | cut -b -16)

mysqlUrl='http://repo.mysql.com'
mariaDBUrl='http://yum.mariadb.org'
#phpUrl='https://rpms.remirepo.net'
LiteSpeedUrl='http://rpms.litespeedtech.com'
mysqlUrl_CN='http://mirrors.ustc.edu.cn/mysql-repo'
mariaDBUrl_CN='http://mirrors.ustc.edu.cn/mariadb/yum'
#phpUrl_CN='https://mirrors.ustc.edu.cn/remi'
LiteSpeedUrl_CN='http://litespeed-rpm.mf8.biz'
isUpdate='0'

# show success message
showOk(){
  echo -e "\\033[34m[OK]\\033[0m $1"
}

# show error message
showError(){
  echo -e "\\033[31m[ERROR]\\033[0m $1"
}

# show notice message
showNotice(){
  echo -e "\\033[36m[NOTICE]\\033[0m $1"
}

# install
runInstall(){
  showNotice 'Installing...'

  showNotice '(Step 1/7) Update YUM packages'

  while true; do
    read -p "Please answer yes or no. [Y/n]" yn
    case $yn in
      [Yy]* ) isUpdate='1'; break;;
      [Nn]* ) isUpdate='0'; break;;
    esac
  done

  showNotice '(Step 2/7) Input server IPv4 Address'
  read -p "IP address: " -r -e -i "${ipAddress}" ipAddress
  if [ "${ipAddress}" = '' ]; then
    showError 'Invalid IP Address'
    exit
  fi

  showNotice "(Step 3/7) Select the MySQL version"
  echo "1) MariaDB-5.5"
  echo "2) MariaDB-10.0"
  echo "3) MariaDB-10.1"
  echo "4) MariaDB-10.2"
  echo "5) MariaDB-10.3"
  echo "6) MySQL-5.5"
  echo "7) MySQL-5.6"
  echo "8) MySQL-5.7"
  echo "9) MySQL-8.0"
  echo "0) Not need"
  read -p 'MySQL [1-9,0]: ' -r -e -i 0 mysqlV
  if [ "${mysqlV}" = '' ]; then
    showError 'Invalid MySQL version'
    exit
  fi

  showNotice "(Step 4/7) Select the PHP version"
  echo "1) PHP-5.4"
  echo "2) PHP-5.5"
  echo "3) PHP-5.6"
  echo "4) PHP-7.0"
  echo "5) PHP-7.1"
  echo "6) PHP-7.2"
  echo "7) PHP-7.3"
  echo "0) Not need"
  read -p 'PHP [1-6,0]: ' -r -e -i 7 phpV
  if [ "${phpV}" = '' ]; then
    showError 'Invalid PHP version'
    exit
  fi

  showNotice "(Step 5/7) Install LiteSpeed or Not?"
  echo "1) Install LiteSpeed"
  echo "0) Not need"
  read -p 'LiteSpeed [1,0]: ' -r -e -i 1 LiteSpeedV
  if [ "${LiteSpeedV}" = '' ]; then
    showError 'Invalid LiteSpeed select'
    exit
  fi

  showNotice "(Step 6/7) Select the DB tool version"
  echo "1) Adminer"
  echo "2) phpMyAdmin"
  echo "0) Not need"
  read -p 'DB tool [1-3]: ' -r -e -i 0 dbV
  if [ "${dbV}" = '' ]; then
    showError 'Invalid DB tool version'
    exit
  fi

  showNotice "(Step 7/7) Use a mirror server to download rpms"
  echo "1) Source station"
  echo "2) China Mirror station"
  read -p 'Proxy server [1-2]: ' -r -e -i 2 freeV
  if [ "${freeV}" = '' ]; then
    showError 'Invalid Proxy server'
    exit
  fi

  showNotice "Use Triay Key or Serial No. to activate LiteSpeed"
  echo "1) Triay Key, Please put The Trial.key in /root/trial.key"
  echo "2) Serial No. Recommend"
  read -p 'Activation method [1-2]: ' -r -e -i 2 acV
  if [ "${acV}" = '2' ]; then
      showNotice "Enter The Serial No. here."
      read -p 'Serial No.: ' -r -e acnoV
        if [ "${acnoV}}" = '' ]; then
          showError 'Invalid Serial No.'
          exit
        fi
    elif [ "${acV}" = '' ]; then
      showError 'Invalid Activation method'
      exit
  fi


  [ "${isUpdate}" = '1' ] && yum update -y
  [ ! -x "/usr/bin/wget" ] && yum install wget -y
  [ ! -x "/usr/bin/curl" ] && yum install curl -y
  [ ! -x "/usr/bin/unzip" ] && yum install unzip -y

  if [ ! -d "/tmp/LLStack-${envType}" ]; then
    cd /tmp || exit
    if [ ! -f "LLStack-${envType}.zip" ]; then
      if ! curl -L --retry 3 -o "LLStack-${envType}.zip" "https://github.com/ivmm/LLStack/archive/${envType}.zip"
      then
        showError "LLStack-${envType} download failed!"
        exit
      fi
    fi
    unzip -q "LLStack-${envType}.zip"
  fi

  [ -s /etc/selinux/config ] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  setenforce 0 >/dev/null 2>&1

  yumRepos=$(find /etc/yum.repos.d/ -maxdepth 1 -name "*.repo" -type f | wc -l)

  startDate=$(date)
  startDateSecond=$(date +%s)

  showNotice 'Installing'

  mysqlRepoUrl=${mysqlUrl}
  mariaDBRepoUrl=${mariaDBUrl}
  #phpRepoUrl=${phpUrl}
  LiteSpeedRepoUrl=${LiteSpeedUrl}

  if [ "${freeV}" = "2" ]; then
    mysqlRepoUrl=${mysqlUrl_CN}
    mariaDBRepoUrl=${mariaDBUrl_CN}
    #phpRepoUrl=${phpUrl_CN}
    LiteSpeedRepoUrl=${LiteSpeedUrl_CN}
  fi

  yum install -y epel-release yum-utils iptables iptables-services

  if [ "${mysqlV}" != '0' ]; then
  yum -y remove mariadb*
    if [[ "${mysqlV}" = "1" || "${mysqlV}" = "2" || "${mysqlV}" = "3" || "${mysqlV}" = "4" || "${mysqlV}" = "5" ]]; then
      mariadbV='10.1'
      installDB='mariadb'
      case ${mysqlV} in
        1)
        mariadbV='5.5'
        ;;
        2)
        mariadbV='10.0'
        ;;
        3)
        mariadbV='10.1'
        ;;
        4)
        mariadbV='10.2'
        ;;
        5)
        mariadbV='10.3'
        ;;
      esac
      echo -e "[mariadb]\\nname = MariaDB\\nbaseurl = ${mariaDBRepoUrl}/${mariadbV}/centos7-amd64\\ngpgkey=${mariaDBRepoUrl}/RPM-GPG-KEY-MariaDB\\ngpgcheck=1" > /etc/yum.repos.d/mariadb.repo
    elif [[ "${mysqlV}" = "6" || "${mysqlV}" = "7" || "${mysqlV}" = "8" || "${mysqlV}" = "9" ]]; then
      rpm --import /tmp/LLStack-${envType}/keys/RPM-GPG-KEY-mysql
      rpm -Uvh ${mysqlRepoUrl}/mysql-community-release-el7.rpm
      find /etc/yum.repos.d/ -maxdepth 1 -name "mysql-community*.repo" -type f -print0 | xargs -0 sed -i "s@${mysqlUrl}@${mysqlRepoUrl}@g"
      
      installDB='mysqld'

      case ${mysqlV} in
        6)
        yum-config-manager --enable mysql55-community
        yum-config-manager --disable mysql56-community mysql57-community mysql80-community
        ;;
        7)
        yum-config-manager --enable mysql56-community
        yum-config-manager --disable mysql55-community mysql57-community mysql80-community
        ;;
        8)
        yum-config-manager --enable mysql57-community
        yum-config-manager --disable mysql55-community mysql56-community mysql80-community
        ;;
        9)
        yum-config-manager --enable mysql80-community
        yum-config-manager --disable mysql55-community mysql56-community mysql57-community
        sed -i "s@${mysqlUrl}@${mysqlRepoUrl}@g" /etc/yum.repos.d/mysql-community.repo
        ;;
      esac
    fi
  fi

  if [ "${phpV}" != '0' ]; then

    case ${phpV} in
      1)
      yum install -y appnode-php54-php-litespeed
      ln -s /opt/appnode/appnode-php54/root/usr/bin/php /usr/sbin/php-check
      ln -s /usr/bin/lsappnode-php54 /usr/bin/lsphp54
      touch /usr/share/lsphp-default-version
      echo "lsphp54" > /usr/share/lsphp-default-version
      ;;
      2)
      yum install -y appnode-php55-php-litespeed
      ln -s /opt/appnode/appnode-php55/root/usr/bin/php /usr/sbin/php-check
      ln -s /usr/bin/lsappnode-php55 /usr/bin/lsphp55
      touch /usr/share/lsphp-default-version
      echo "lsphp55" > /usr/share/lsphp-default-version
      ;;
      3)
      yum install -y appnode-php56-php-litespeed 
      ln -s /opt/appnode/appnode-php56/root/usr/bin/php /usr/sbin/php-check
      ln -s /usr/bin/lsappnode-php56 /usr/bin/lsphp56
      touch /usr/share/lsphp-default-version
      echo "lsphp56" > /usr/share/lsphp-default-version
      ;;
      4)
      yum install -y appnode-php70-php-litespeed
      ln -s /opt/appnode/appnode-php70/root/usr/bin/php /usr/sbin/php-check
      ln -s /usr/bin/lsappnode-php70 /usr/bin/lsphp70
      touch /usr/share/lsphp-default-version
      echo "lsphp70" > /usr/share/lsphp-default-version
      ;;
      5)
      yum install -y appnode-php71-php-litespeed
      ln -s /opt/appnode/appnode-php71/root/usr/bin/php /usr/sbin/php-check
      ln -s /usr/bin/lsappnode-php71 /usr/bin/lsphp71
      touch /usr/share/lsphp-default-version
      echo "lsphp71" > /usr/share/lsphp-default-version
      ;;
      6)
      yum install -y appnode-php72-php-litespeed
      ln -s /opt/appnode/appnode-php72/root/usr/bin/php /usr/sbin/php-check
      ln -s /usr/bin/lsappnode-php72 /usr/bin/lsphp72
      touch /usr/share/lsphp-default-version
      echo "lsphp72" > /usr/share/lsphp-default-version
      ;;
      7)
      yum install -y appnode-php73-php-litespeed
      ln -s /opt/appnode/appnode-php73/root/usr/bin/php /usr/sbin/php-check
      ln -s /usr/bin/lsappnode-php73 /usr/bin/lsphp73
      touch /usr/share/lsphp-default-version
      echo "lsphp73" > /usr/share/lsphp-default-version
      ;;
    esac
  fi

  if [ "${LiteSpeedV}" != '0' ]; then
    systemctl stop httpd.service  
    yum remove httpd appnode-php72-php -y
    rpm -Uvh ${LiteSpeedRepoUrl}/centos/litespeed-repo-1.1-1.el7.noarch.rpm

    LiteSpeedRepo=/etc/yum.repos.d/litespeed.repo

    sed -i "s@${LiteSpeedUrl}@${LiteSpeedRepoUrl}@g" ${LiteSpeedRepo}
  fi

  yum clean all && yum makecache fast

  if [ "${mysqlV}" != '0' ]; then
    if [ "${installDB}" = "mariadb" ]; then
      yum install -y MariaDB-server MariaDB-client MariaDB-common
      mysql_install_db --user=mysql
    elif [ "${installDB}" = "mysqld" ]; then
      yum install -y mysql-community-server

      if [ "${mysqlV}" = "6" ]; then
        mysql_install_db --user=mysql
      elif [ "${mysqlV}" = "7" ]; then
        mysqld --initialize-insecure --user=mysql --explicit_defaults_for_timestamp
      else
        mysqld --initialize-insecure --user=mysql
      fi

      if [ "${mysqlV}" = "9" ]; then
      sed -i "s@# default-authentication-plugin=mysql_native_password@default-authentication-plugin=mysql_native_password@g" /etc/my.cnf
      fi
    fi
  fi

  if [ "${LiteSpeedV}" != '0' ]; then

    yum install lsws -y

    if [ -d "/usr/local/lsws/" ]; then
      mv -bfu /usr/local/lsws/conf/httpd_config.xml /usr/local/lsws/conf/httpd_config.xml.llstack.bak
      mkdir -p /usr/local/lsws/conf/vhosts/
    fi

    cp -a /tmp/LLStack-${envType}/conf/httpd_config.xml /usr/local/lsws/conf/httpd_config.xml
    cp -a /tmp/LLStack-${envType}/conf/vhosts/LLStack-demo.xml /usr/local/lsws/conf/vhosts/LLStack-demo.xml
    chown lsadm:lsadm /usr/local/lsws/conf/httpd_config.xml
    chown -R lsadm:lsadm /usr/local/lsws/conf/vhosts/

    mkdir -p /home/demo/{public_html,logs,ssl,cgi-bin,cache}

    cp -a /tmp/LLStack-${envType}/home/demo/public_html/* /home/demo/public_html/
    cp -a /tmp/LLStack-${envType}/home/demo/ssl/* /home/demo/ssl/

    chown -R nobody:nobody /home/demo/public_html
    chown -R lsadm:lsadm /home/demo/ssl

    if [ "${acnoV}" != '' ]; then
        touch /root/serial.no
        echo "${acnoV}" > /root/serial.no
    fi

    if [ -f "/root/serial.no" ]; then
      cp -a /root/serial.no /usr/local/lsws/conf/serial.no
      /usr/local/lsws/bin/lshttpd -r
    elif [ -f "/root/trial.key" ]; then
      cp -a /root/trial.key /usr/local/lsws/conf/trial.key
      /usr/local/lsws/bin/lshttpd -r
    else
       wget -q -t 1 -T 3 --output-document=/usr/local/lsws/conf/trial.key http://license.litespeedtech.com/reseller/trial.key
    fi



    case ${phpV} in
      1)
      sed -i "s@lsphp73@lsphp54@g" /usr/local/lsws/conf/vhosts/LLStack-demo.xml
      ;;
      2)
      sed -i "s@lsphp73@lsphp55@g" /usr/local/lsws/conf/vhosts/LLStack-demo.xml
      ;;
      3)
      sed -i "s@lsphp73@lsphp56@g" /usr/local/lsws/conf/vhosts/LLStack-demo.xml
      ;;
      4)
      sed -i "s@lsphp73@lsphp70@g" /usr/local/lsws/conf/vhosts/LLStack-demo.xml
      ;;
      5)
      sed -i "s@lsphp73@lsphp71@g" /usr/local/lsws/conf/vhosts/LLStack-demo.xml
      ;;
      6)
      sed -i "s@lsphp73@lsphp72@g" /usr/local/lsws/conf/vhosts/LLStack-demo.xml
      ;;
      7)
      sed -i "s@lsphp73@lsphp73@g" /usr/local/lsws/conf/vhosts/LLStack-demo.xml
      ;;
    esac

  fi

  if [[ "${phpV}" != '0' && "${LiteSpeedV}" != '0' ]]; then
    if [ "${dbV}" = "1" ]; then
      cp -a /tmp/LLStack-${envType}/DB/Adminer /home/demo/public_html/
      sed -i "s/phpMyAdmin/Adminer/g" /home/demo/public_html/index.html
    elif [ "${dbV}" = "2" ]; then
      ## PHP 5.4 仅 PMA 4.0 LTS 支持
      if [ "${phpV}" = "1" ]; then
        cd /home/demo/public_html
        wget https://files.phpmyadmin.net/phpMyAdmin/4.0.10.20/phpMyAdmin-4.0.10.20-all-languages.zip
        unzip phpMyAdmin-4.0.10.20-all-languages.zip
        rm -rf phpMyAdmin-4.0.10.20-all-languages.zip
        mv phpMyAdmin-4.0.10.20-all-languages phpMyAdmin
      ## PHP 5.5-7.0 仅 PMA 4.8 LTS 支持
      elif [ "${phpV}}" = "2" || "${phpV}" = "3" || "${phpV}" = "4" ]; then
        cd /home/demo/public_html
        wget https://files.phpmyadmin.net/phpMyAdmin/4.8.5/phpMyAdmin-4.8.5-all-languages.zip
        unzip phpMyAdmin-4.8.5-all-languages.zip
        rm -rf phpMyAdmin-4.8.5-all-languages.zip
        mv phpMyAdmin-4.8.5-all-languages phpMyAdmin
      ## PHP 7.1+ 支持 4.8，5.0+
      else
        cd /home/demo/public_html
        wget https://files.phpmyadmin.net/phpMyAdmin/4.8.5/phpMyAdmin-4.8.5-all-languages.zip
        unzip phpMyAdmin-4.8.5-all-languages.zip
        rm -rf phpMyAdmin-4.8.5-all-languages.zip
        mv phpMyAdmin-4.8.5-all-languages phpMyAdmin
      fi
    fi
  fi

  if [ "${dbV}" = "2" ]; then
  mkdir -p /home/demo/public_html/phpMyAdmin/tmp/
  chmod 0777 /home/demo/public_html/phpMyAdmin/tmp/
  cp /home/demo/public_html/phpMyAdmin/libraries/config.default.php /home/demo/public_html/phpMyAdmin/config.inc.php
  sed -i "s@UploadDir.*@UploadDir'\] = 'upload';@" /home/demo/public_html/phpMyAdmin/config.inc.php
  sed -i "s@SaveDir.*@SaveDir'\] = 'save';@" /home/demo/public_html/phpMyAdmin/config.inc.php
  sed -i "s@host'\].*@host'\] = '127.0.0.1';@" /home/demo/public_html/phpMyAdmin/config.inc.php
  sed -i "s@blowfish_secret.*;@blowfish_secret\'\] = \'$(cat /dev/urandom | head -1 | base64 | head -c 45)\';@" /home/demo/public_html/phpMyAdmin/config.inc.php
  fi

  showNotice "Start service"

  if [ "${mysqlV}" != '0' ]; then
    if [[ "${mysqlV}" = '1' || "${mysqlV}" = '2' ]]; then
      service mysql start
    else
      systemctl enable ${installDB}.service
      systemctl start ${installDB}.service
    fi

    mysqladmin -u root password "${mysqlPWD}"
    mysqladmin -u root -p"${mysqlPWD}" -h "localhost" password "${mysqlPWD}"
    mysql -u root -p"${mysqlPWD}" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');DELETE FROM mysql.user WHERE User='';DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';FLUSH PRIVILEGES;"
    if [ "${mysqlV}" = "9" ]; then
    mysql -u root -p"${mysqlPWD}" -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY \"${mysqlPWD}\";FLUSH PRIVILEGES;"
    fi

    echo "${mysqlPWD}" > /home/initialPWD.txt
    rm -rf /var/lib/mysql/test
  fi

  if [ "${LiteSpeedV}" != '0' ]; then
    LSPASSRAND=`head -c 100 /dev/urandom | tr -dc a-z0-9A-Z |head -c 16`
    ENCRYPT_PASS=`/usr/local/lsws/admin/fcgi-bin/admin_php5 -q /usr/local/lsws/admin/misc/htpasswd.php $LSPASSRAND`
    echo "llstackadmin:$ENCRYPT_PASS" > /usr/local/lsws/admin/conf/htpasswd 
    touch /root/defaulthtpasswd
    echo "llstackadmin:$LSPASSRAND" > /root/defaulthtpasswd
    systemctl restart lsws.service
  fi

  wget -P /root/ https://raw.githubusercontent.com/ivmm/LLStack/master/vhost.sh

  if [[ -f "/usr/sbin/mysqld" || -f "/usr/sbin/php-check" || -f "/usr/local/lsws/bin/httpd" ]]; then
    echo "================================================================"
    echo -e "\\033[42m [LLStack] Install completed. \\033[0m"

    if [ "${LiteSpeedV}" != '0' ]; then
      echo -e "\\033[34m Web Demo Site: \\033[0m http://${ipAddress}"
      echo -e "\\033[34m Web Demo Dir: \\033[0m /home/demo/public_html"
      echo -e "\\033[34m LiteSpeed: \\033[0m /usr/local/lsws/"
      echo -e "\\033[34m LiteSpeed WebAdmin Console URL: \\033[0m http://${ipAddress}:7080"
      echo -e "\\033[34m LiteSpeed WebAdmin Console Username: \\033[0m llstackadmin"
      echo -e "\\033[34m LiteSpeed WebAdmin Console Paasword: \\033[0m $LSPASSRAND"
    fi

    if [ "${phpV}" != '0' ]; then
      case ${phpV} in
      1)
      echo -e "\\033[34m PHP: \\033[0m /etc/opt/appnode/appnode-php54/"
      ;;
      2)
      echo -e "\\033[34m PHP: \\033[0m /etc/opt/appnode/appnode-php55/"
      ;;
      3)
      echo -e "\\033[34m PHP: \\033[0m /etc/opt/appnode/appnode-php56/"
      ;;
      4)
      echo -e "\\033[34m PHP: \\033[0m /etc/opt/appnode/appnode-php70/"
      ;;
      5)
      echo -e "\\033[34m PHP: \\033[0m /etc/opt/appnode/appnode-php71/"
      ;;
      6)
      echo -e "\\033[34m PHP: \\033[0m /etc/opt/appnode/appnode-php72/"
      ;;
      7)
      echo -e "\\033[34m PHP: \\033[0m /etc/opt/appnode/appnode-php73/"
      ;;
    esac
    fi

    if [[ "${mysqlV}" != '0' && -f "/usr/sbin/mysqld" ]]; then
      if [ "${installDB}" = "mariadb" ]; then
        echo -e "\\033[34m MariaDB Data: \\033[0m /var/lib/mysql/"
        echo -e "\\033[34m MariaDB User: \\033[0m root"
        echo -e "\\033[34m MariaDB Password: \\033[0m ${mysqlPWD}"
      elif [ "${installDB}" = "mysqld" ]; then
        echo -e "\\033[34m MySQL Data: \\033[0m /var/lib/mysql/"
        echo -e "\\033[34m MySQL User: \\033[0m root"
        echo -e "\\033[34m MySQL Password: \\033[0m ${mysqlPWD}"
      fi
    fi

    echo "Start time: ${startDate}"
    echo "Completion time: $(date) (Use: $((($(date +%s)-startDateSecond)/60)) minute)"
    echo "Use: $((($(date +%s)-startDateSecond)/60)) minute"
    echo -e "For more details see \\033[34m https://llstack.com \\033[0m"
    echo "================================================================"
  else
    echo -e "\\033[41m [LLStack] Sorry, Install Failed. \\033[0m"
    echo "Please contact us: https://github.com/ivmm/LLStack/issues"
  fi
}

while :
do
clear
  echo '  _      _       _____ _             _    '
  echo ' | |    | |     / ____| |           | |   '
  echo ' | |    | |    | (___ | |_ __ _  ___| | __'
  echo ' | |    | |     \___ \| __/ _` |/ __| |/ /'
  echo ' | |____| |____ ____) | || (_| | (__|   < '
  echo ' |______|______|_____/ \__\__,_|\___|_|\_\'
  echo ''
  echo -e "For more details see \033[4mhttps://llstack.com\033[0m"
  echo ''
  showNotice 'Please select your operation:'
  echo '1) Install'
  echo '2) Upgrade packages'
  echo '3) Exit'
  read -p 'Select an option [1-3]: ' -r -e operation
  case ${operation} in
    1)
      clear
      runInstall
    exit
    ;;
    2)
      clear
      showNotice "Checking..."
      yum upgrade
    exit
    ;;
    3)
      showNotice "Nothing to do..."
    exit
    ;;
  esac
done
