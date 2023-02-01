FROM php:7.4-fpm

# install dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    nginx \
    supervisor \
    libmemcached-dev \
    libz-dev \
    libonig-dev \
    libpq-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libssl-dev \
    libmcrypt-dev \
    libxml2-dev \
    zip \
    unzip \
    build-essential \
    libaio1 \
    libzip-dev \
    curl \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && rm /var/log/lastlog /var/log/faillog

# install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN composer --version
RUN php -r "unlink('composer-setup.php');"	

# install oracle client	
RUN curl -o instantclient-basic-193000.zip https://download.oracle.com/otn_software/linux/instantclient/193000/instantclient-basic-linux.x64-19.3.0.0.0dbru.zip \
    && unzip instantclient-basic-193000.zip -d /usr/lib/oracle/ \
    && rm instantclient-basic-193000.zip \
    && curl -o instantclient-sdk-193000.zip https://download.oracle.com/otn_software/linux/instantclient/193000/instantclient-sdk-linux.x64-19.3.0.0.0dbru.zip \
    && unzip instantclient-sdk-193000.zip -d /usr/lib/oracle/ \
    && rm instantclient-sdk-193000.zip \
    && echo /usr/lib/oracle/instantclient_19_3 > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig

ENV LD_LIBRARY_PATH /usr/lib/oracle/instantclient_19_3

# install php extension
RUN docker-php-ext-install zip pdo_mysql mysqli tokenizer bcmath opcache pcntl \
    && docker-php-ext-configure oci8 --with-oci8=instantclient,/usr/lib/oracle/instantclient_19_3 \
    && docker-php-ext-install -j$(nproc) oci8 \
    # Install the PHP gd library
    && docker-php-ext-configure gd \
    --with-jpeg-dir=/usr/lib \
    --with-freetype-dir=/usr/include/freetype2 && \
    docker-php-ext-install gd

# custom config php		
COPY ./config/php/custom.ini /usr/local/etc/php/conf.d
COPY ./config/php/pool.d/custom.conf /usr/local/etc/php/conf.d

COPY nginx.conf /etc/nginx/nginx.conf
COPY configure.sh /configure.sh
COPY supervisord.conf /etc/supervisord.conf

EXPOSE 80/tcp
RUN sh /configure.sh
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]