#FROM php:7.3-fpm-buster
FROM php:7.4-fpm-buster

# setup user and group
RUN set -x \
    && addgroup --system --gid 1010 nginx \
    &&  adduser --system --disabled-login --ingroup nginx --no-create-home  --gecos "nginx user" --shell /bin/false --uid 1010 nginx

# create a docker-entrypoint.d directory
RUN mkdir /entrypoint.d

COPY entrypoint.sh /
COPY scripts/10-default-listen-on-ipv6.sh /entrypoint.d
COPY scripts/20-envsubst-on-template.sh /entrypoint.d
COPY scripts/30-tune-worker-process.sh /entrypoint.d

RUN chmod +x /entrypoint.d/10-default-listen-on-ipv6.sh \
    && chmod +x /entrypoint.d/20-envsubst-on-template.sh \
    && chmod +x /entrypoint.d/30-tune-worker-process.sh \
    && chmod +x /entrypoint.sh

# install dependencies
RUN apt-get update \
    && apt-get install -y apt-utils gnupg \
    && echo "deb http://nginx.org/packages/mainline/debian/ buster nginx" >> /etc/apt/sources.list \
    && echo "deb-src http://nginx.org/packages/mainline/debian/ buster nginx" >> /etc/apt/sources.list \
    && curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add - \
    && apt-get update \
    && apt-get install -y nginx \
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
    nano 

RUN apt-get clean \
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

# install php extension
RUN docker-php-ext-install zip pdo_mysql mysqli tokenizer bcmath opcache pcntl \
    && docker-php-ext-configure oci8 --with-oci8=instantclient,/usr/lib/oracle/instantclient_19_3 \
    && docker-php-ext-install -j$(nproc) oci8 

# install the PHP gd library
# PHP 7.4
# issue on PHP 7.4, fix: https://github.com/docker-library/php/issues/912#issuecomment-559918036
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install gd    
# PHP 7.3
# RUN docker-php-ext-configure gd \
#     --with-jpeg-dir=/usr/lib \
#     --with-freetype-dir=/usr/include/freetype2 && \
#     docker-php-ext-install gd

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGQUIT

RUN rm -Rf /etc/nginx/nginx.conf \
    && rm -Rf /etc/nginx/conf.d/default.conf \
    && mkdir -p /var/log/supervisor

COPY config/supervisord.conf /etc/supervisord.conf
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx-default.conf /etc/nginx/conf.d/default.conf

CMD ["/entrypoint.sh"]