FROM ubuntu:trusty
MAINTAINER AAyupov <aayupov@nefco.ru>

# Downloads URLs
ENV MS_ODBC_URL https://download.microsoft.com/download/B/C/D/BCDD264C-7517-4B7D-8159-C99FC5535680/RedHat6/msodbcsql-11.0.2270.0.tar.gz
ENV FIX_SCRIPT Microsoft--SQL-Server--ODBC-Driver-1.0-for-Linux-Fixed-Install-Scripts
ENV FIX_SCRIPT_URL https://github.com/Andrewpk/${FIX_SCRIPT}/archive/master.zip

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get update && apt-get -y install aptitude wget unzip make gcc libkrb5-3 libgssapi-krb5-2

# Download ODBC install files & scripts
RUN cd /tmp && wget -O msodbcsql.tar.gz ${MS_ODBC_URL} && wget -O odbc-fixed.zip ${FIX_SCRIPT_URL}

# Unzip downloaded files
RUN cd /tmp && tar -xzf ./msodbcsql.tar.gz && unzip -o ./odbc-fixed.zip && cp ./${FIX_SCRIPT}-master/* ./msodbcsql-11.0.2270.0

# Run install scripts
RUN cd /tmp/msodbcsql-11.0.2270.0 && yes YES | ./build_dm.sh --accept-warning --libdir=/usr/lib/x86_64-linux-gnu && \
    ./install.sh install --accept-license --force

# Install apache and php5 with dependencies
RUN apt-get update &&  apt-get -y install \

    #apache
     apache2 \
     apache2-utils \

    # php5
    php5 \
    php5-gd \
    php5-imagick \
    php5-json \
    php5-mssql \
    php5-curl \
    php5-odbc \

    #other
    curl &&\
    apt-get -y clean && \
    apt-get -y autoremove

# Clean installation files
RUN apt-get remove -y aptitude wget unzip make gcc && apt-get -y autoremove && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set apache and php configs
COPY configs/apache.conf /etc/apache2/sites-available/000-default.conf
COPY configs/php.ini /etc/php5/apache2/php.ini
# set freeTDS configs
COPY configs/freetds.conf /etc/freetds/

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
RUN a2enmod rewrite && php5enmod mssql

EXPOSE 80
