##########################################
############# FRONTEND ###################
##########################################
FROM node:16.18.1-alpine3.15 as nodebuild

WORKDIR "/var/www/html"
COPY --chown=nobody:nobody . /var/www/html


RUN echo 'Checking if all ENV vars in Dockerfile are replaced. Next line will fail if not.'
RUN ! fgrep " '\$" Dockerfile

# gettext is needed for envsubst to replace variables
RUN apk add gettext

# setting up .env file
ENV APP_KEY '$APP_KEY'
ENV APP_ENV '$APP_ENV'
ENV APP_URL '$APP_URL'
ENV DB_HOST '$DB_HOST'
ENV DB_PORT '$DB_PORT'
ENV DB_DATABASE '$DB_DATABASE'
ENV DB_USERNAME '$DB_USERNAME'
ENV DB_PASSWORD '$DB_PASSWORD'
ENV MAILGUN_DOMAIN '$MAILGUN_DOMAIN'
ENV MAILGUN_SECRET '$MAILGUN_SECRET'

RUN envsubst < .env.docker-production > .env
RUN cat .env


##########################################
######## BACKEND & FINAL STAGE ###########
##########################################
# https://hub.docker.com/r/trafex/php-nginx/tags
# last one that supports php7.3
FROM trafex/alpine-nginx-php7:1.9.0

USER root

# ADD https://php.hernandev.com/key/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub
# alpine php modules https://github.com/codecasts/php-alpine
# RUN apk --update-cache add ca-certificates && \
#     echo "https://php.hernandev.com/v3.15/php-8.1" >> /etc/apk/repositories

RUN apk update && \
    apk add \
        git \ 
        php73-bz2 \ 
        php73-gd \ 
        php73-pecl-imagick \ 
        php73-fileinfo \ 
        php73-simplexml \ 
        php73-xmlwriter \ 
        php73-tokenizer \ 
        php73-pdo_mysql \ 
        php73-pdo \ 
        libsodium-dev \ 
        php73-sodium \
        php73-zip && \ 
    rm -rf /var/cache/apk/* /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Copy all files with compiled frontend to current stage
COPY --from=nodebuild /var/www/html /var/www/html

# Install composer from the official image
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Make sure all log files used in other files are present
RUN touch /var/www/html/storage/logs/laravel.log; \
    chown nobody:nobody /var/www/html/storage/logs/*
RUN ls -lah /var/www/html/storage/logs

# NGINX stuff
RUN mkdir -p /etc/nginx/conf.d/
COPY .docker/nginx/nginx-laravel.conf /etc/nginx/conf.d/



USER nobody


# compile backend
RUN composer install --no-ansi --no-dev --no-interaction --no-progress --optimize-autoloader

# other commands that can be executed without breaking backwards compatibility (not influencing currently running service)
RUN php artisan config:cache
