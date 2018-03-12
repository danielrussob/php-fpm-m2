FROM dnafactory/php-fpm-71

RUN apt-get update -yqq && \
    apt-get -y install libxml2-dev php-soap libjpeg62-turbo-dev libxslt-dev && \
    docker-php-ext-install soap \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove

ADD php.ini /usr/local/etc/php

RUN pecl install xdebug && \
    docker-php-ext-enable xdebug
COPY ./xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

RUN docker-php-ext-install zip
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install exif
RUN docker-php-ext-install mysqli

RUN apt-get update -yqq && \
    apt-get install -y zlib1g-dev libicu-dev g++ && \
    docker-php-ext-configure intl && \
    docker-php-ext-install intl xsl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove

USER root
RUN apt-get update -yqq && \
        apt-get install -y --force-yes jpegoptim optipng pngquant gifsicle \
        && rm -rf /var/lib/apt/lists/* \
        && apt-get purge -y --auto-remove

RUN apt-get update -y && \
    apt-get install -y libmagickwand-dev imagemagick && \
    pecl install imagick && \
    docker-php-ext-enable imagick \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove

#
#--------------------------------------------------------------------------
# Final Touch
#--------------------------------------------------------------------------
#

RUN apt-get update && apt-get install -y \
    mysql-client \
    vim \
    telnet \
    netcat \
    git-core \
    zip \
	openssh-client \
	openssh-server \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get purge -y --auto-remove

RUN curl -s http://getcomposer.org/installer | php && \
    echo "export PATH=${PATH}:/var/www/vendor/bin" >> ~/.bashrc && \
    mv composer.phar /usr/local/bin/composer

RUN sed  -ibak -re "s/PermitRootLogin without-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
RUN echo "root:root" | chpasswd

RUN systemctl enable ssh

RUN mkdir /var/www/sites-available
RUN mkdir /var/www/logs
RUN mkdir /var/www/dumps

RUN usermod -u 1000 www-data
RUN usermod -s /bin/bash www-data

COPY ./magento2.conf /var/www/sites-available/magento2.conf
RUN rm /var/www/sites-available/default.conf -Rf
RUN mkdir /var/www/magento2
RUN chown www-data:www-data /var/www/magento2 -Rf

WORKDIR /var/www

RUN cd ~ && \
    curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh && \
    bash nodesource_setup.sh && \
    apt-get update && apt-get install nodejs && \
    apt-get install build-essential

RUN npm install -g grunt grunt-cli

#CMD ["php-fpm"]
CMD service ssh restart && php-fpm

EXPOSE 9000