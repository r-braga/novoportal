FROM debian:7.8
MAINTAINER Rousseau L. Braga "rbraga@tce.ro.gov.br"

ENV DEBIAN_FRONTEND Noninteractive

RUN apt-get update && apt-get -y install apt git wget curl

#Adicionando os pacotes para a versão 5.6 no Debian 7.8
RUN echo "deb http://packages.dotdeb.org wheezy-php56 all" >> /etc/apt/sources.list.d/dotdeb.list
RUN echo "deb-src http://packages.dotdeb.org wheezy-php56 all" >> /etc/apt/sources.list.d/detdeb.list
#Adicionando o HHVM no Debain 7.8
RUN echo deb http://dl.hhvm.com/debian wheezy main | tee /etc/apt/sources.list.d/hhvm.list

RUN wget http://www.dotdeb.org/dotdeb.gpg -O- | apt-key add -
RUN wget -O - http://dl.hhvm.com/conf/hhvm.gpg.key | apt-key add -

RUN apt-get update && apt-get -y install php5-mcrypt \
             php5-sybase \
             hhvm \
             apache2 \
             redis-server \
             memcached \
             zsh \
             beanstalkd


# create docker group and app user
RUN groupadd -g 999 docker \
    && useradd \
         -G sudo,docker \
         -d /home/app \
         -m \
         -p $(openssl passwd 123app4) \
         -s $(which zsh) \
         app
USER app

# prepare home dir
ENV HOME /home/app
ENV HOMESRC ${HOME}/local/src
ENV HOMEBIN ${HOME}/local/bin
RUN mkdir -p $HOME/public \
    && mkdir -p $HOMESRC \
    && mkdir -p $HOMEBIN

RUN /usr/sbin/a2enmod rewrite

# This is no longer available by default in jessie's apache2
#RUN /usr/sbin/a2enmod socache_shmcb || true

# Note: "default" is enabled in the default installation, and "default-ssl" is
# enabled in the eboraas/apache image, so no need to recreate the symlinks
# here, just copy the new site definitions into place
#ADD default /etc/apache2/sites-available/
#ADD default-ssl /etc/apache2/sites-available/

RUN /usr/bin/curl -sS https://getcomposer.org/installer |/usr/bin/php
RUN /bin/mv composer.phar /usr/local/bin/composer
RUN /usr/local/bin/composer \
 create-project \
 laravel/laravel \
 /var/www/laravel --prefer-dist
RUN /bin/mkdir -p /var/www/laravel/app/storage
RUN /bin/chown www-data:www-data -R /var/www/laravel/app/storage

# install oh-my-zsh
RUN git clone https://github.com/robbyrussell/oh-my-zsh.git \
        ${HOME}/.oh-my-zsh \
        && cp $HOME/.oh-my-zsh/templates/zshrc.zsh-template ${HOME}/.zshrc \
        && echo '\n' >> ${HOME}/.zshrc \
        && echo '# local resources' >> ${HOME}/.zshrc \
        && echo 'source $HOME/.bash_aliases' >> ${HOME}/.zshrc

ENV TERM xterm-256color
VOLUME ["/var/www"]
WORKDIR /home/app
CMD["/usr/bin/zsh"]

EXPOSE 80
EXPOSE 443

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]

