FROM golang as configurability_php
MAINTAINER brian.wilkinson@1and1.co.uk
WORKDIR /go/src/github.com/1and1internet/configurability
RUN git clone https://github.com/1and1internet/configurability.git . \
	&& make php\
	&& echo "configurability php plugin successfully built"

FROM 1and1internet/debian-8-apache:latest
MAINTAINER brian.wilkinson@fasthosts.co.uk
ARG DEBIAN_FRONTEND=noninteractive
COPY files /
COPY --from=configurability_php /go/src/github.com/1and1internet/configurability/bin/plugins/php.so /opt/configurability/goplugins
ARG PHP_VERSION=5.6
RUN \
    apt-get update && \
    apt-get install -y libapache2-mod-php${PHP_VERSION} php${PHP_VERSION}-bcmath \
          php${PHP_VERSION}-bz2 php${PHP_VERSION}-cli php${PHP_VERSION}-common \
          php${PHP_VERSION}-curl php${PHP_VERSION}-dba php${PHP_VERSION}-gd \
          php${PHP_VERSION}-gmp php${PHP_VERSION}-imap php${PHP_VERSION}-intl \
          php${PHP_VERSION}-ldap php${PHP_VERSION}-mbstring \
          php${PHP_VERSION}-mcrypt php${PHP_VERSION}-mysql \
          php${PHP_VERSION}-odbc php${PHP_VERSION}-pgsql php${PHP_VERSION}-recode \
          php${PHP_VERSION}-snmp php${PHP_VERSION}-soap php${PHP_VERSION}-sqlite \
          php${PHP_VERSION}-tidy php${PHP_VERSION}-xml php${PHP_VERSION}-xmlrpc \
          php${PHP_VERSION}-xsl php${PHP_VERSION}-zip && \
    apt-get install -y imagemagick graphicsmagick php-imagick php-mongodb php-fxsl curl && \
    sed -i -e 's/max_execution_time = 30/max_execution_time = 300/g' /etc/php/${PHP_VERSION}/apache2/php.ini && \
    sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 256M/g' /etc/php/${PHP_VERSION}/apache2/php.ini && \
    sed -i -e 's/post_max_size = 8M/post_max_size = 512M/g' /etc/php/${PHP_VERSION}/apache2/php.ini && \
    sed -i -e 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php/${PHP_VERSION}/apache2/php.ini && \
    sed -i -e 's/DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/g' \
                  /etc/apache2/mods-available/dir.conf && \
    mkdir -p /usr/src/tmp/ioncube && \
    curl -fSL "http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64_5.1.2.tar.gz" -o /usr/src/tmp/ioncube_loaders_lin_x86-64_5.1.2.tar.gz && \
    tar xfz /usr/src/tmp/ioncube_loaders_lin_x86-64_5.1.2.tar.gz -C /usr/src/tmp/ioncube && \
    cp /usr/src/tmp/ioncube/ioncube/ioncube_loader_lin_${PHP_VERSION}.so /usr/lib/php/20131226/ && \
    rm -rf /usr/src/tmp/ && \
    mkdir /tmp/composer/ && \
    cd /tmp/composer && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod a+x /usr/local/bin/composer && \
    cd / && \
    rm -rf /tmp/composer && \
    apt-get remove curl && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    chmod 777 -R /var/www  && \
    apache2ctl -t && \
    mkdir -p /run /var/lib/apache2 /var/lib/php && \
    chmod -R 777 /run /var/lib/apache2 /var/lib/php /etc/php/${PHP_VERSION}/apache2/php.ini
