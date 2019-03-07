#!/bin/bash

set -e
set -x

# Add repositories
# zypper --non-interactive ar http://download.opensuse.org/repositories/devel:/languages:/php/openSUSE_Leap_15.0/ php
#zypper --non-interactive ar https://download.opensuse.org/update/leap/42.3/oss/ openSUSE-Leap-42.3-Update-Oss
zypper --non-interactive ar https://download.opensuse.org/update/leap/15.1/oss/ openSUSE-Leap-15.1-Update-Oss
zypper --non-interactive ar https://download.opensuse.org/repositories/devel:/libraries:/c_c++/openSUSE_Leap_15.0/ c_c++_opensuse_leap_15.0
zypper --non-interactive ar http://download.opensuse.org/repositories/devel:/languages:/python/openSUSE_Leap_15.0/ python

# Install Git before we add the SCM repository (the SCM repository contains Git 2.11, which is broken).
zypper --gpg-auto-import-keys --non-interactive in --force-resolution git

# Lock the git package to the current version
# zypper --non-interactive al git

# Add SCM package for other tools (Subversion, Mercurial)...
# zypper --non-interactive ar http://download.opensuse.org/repositories/devel:/tools:/scm/openSUSE_Leap_42.3/ scm

# nginx from openSUSE-Leap-42.3-Update-Oss conflict with git, so use specificly Leap-15.0-Oss version
zypper --gpg-auto-import-keys --non-interactive in --force-resolution --repo repo-oss nginx augeas-lenses
# Install requirements
zypper --gpg-auto-import-keys --non-interactive in --force-resolution php7-fpm php7-mbstring php7-mysql php7-curl php7-pcntl php7-gd php7-openssl php7-ldap php7-fileinfo php7-posix php7-json php7-iconv php7-ctype php7-zip php7-sockets which nodejs8 npm ca-certificates ca-certificates-mozilla ca-certificates-cacert sudo subversion mercurial php7-xmlwriter php7-opcache ImageMagick postfix glibc-locale

# Build and install APCu
zypper --non-interactive install --force-resolution autoconf automake binutils cpp gcc glibc-devel libatomic1 libgomp1 libitm1 libltdl7 libmpc3 libpcre16-0 libpcrecpp0 libpcreposix0 libstdc++-devel libtool libtsan0 libxml2-devel libxml2-tools linux-glibc-devel m4 make ncurses-devel pcre-devel php7-devel php7-pear php7-zlib pkg-config readline-devel tack xz-devel zlib-devel

# fix pecl call php bug. pecl use php -n, without reading php.ini and ssl not supported wtf
sed -i 's|$PHP -C -n -q |$PHP -C -q |' /usr/bin/pecl
printf "\n" | pecl install apcu

# Remove cached things that pecl left in /tmp/
rm -rf /tmp/*

# Install a few extra things
zypper --non-interactive install --force-resolution mariadb-client vim vim-data

# Force reinstall cronie
zypper --non-interactive install -f cronie

# add by adam@xiimoon
# some stuff
zypper --gpg-auto-import-keys --non-interactive in python-pip
pip install --upgrade pip
pip install pygments
pip install supervisor

# Create users and groups
echo "nginx:x:497:495:user for nginx:/var/lib/nginx:/bin/false" >> /etc/passwd
echo "nginx:!:495:" >> /etc/group
echo "PHABRICATOR:x:2000:2000:user for phabricator:/srv/phabricator:/bin/bash" >> /etc/passwd
echo "wwwgrp-phabricator:!:2000:nginx" >> /etc/group

# Set up the Phabricator code base
mkdir /srv/phabricator
chown PHABRICATOR:wwwgrp-phabricator /srv/phabricator
cd /srv/phabricator
sudo -u PHABRICATOR git clone https://github.com/phacility/libphutil.git /srv/phabricator/libphutil
sudo -u PHABRICATOR git clone https://github.com/phacility/arcanist.git /srv/phabricator/arcanist
sudo -u PHABRICATOR git clone https://github.com/phacility/phabricator.git /srv/phabricator/phabricator
sudo -u PHABRICATOR git clone https://github.com/PHPOffice/PHPExcel.git /srv/phabricator/PHPExcel
sudo -u PHABRICATOR git clone https://github.com/wikimedia/phabricator-extensions-Sprint.git /srv/phabricator/libext/sprint
cd /

# nodejs ws for aphlict
cd /usr/lib/
npm install ws

# Clone Let's Encrypt
git clone https://github.com/letsencrypt/letsencrypt /srv/letsencrypt
cd /srv/letsencrypt
./letsencrypt-auto-source/letsencrypt-auto --help
cd /
