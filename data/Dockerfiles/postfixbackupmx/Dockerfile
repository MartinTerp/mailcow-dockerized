FROM debian:stretch-slim
LABEL maintainer "Martin Terp <terp@boot.dk>"

ARG DEBIAN_FRONTEND=noninteractive
ENV LC_ALL C

RUN apt-get update && apt-get install -y --no-install-recommends \
	ca-certificates \
	curl \
	cron \
	perl \
        libwww-perl \
        libjson-perl \
	postfix \
	postfix-pcre \
	syslog-ng \
	syslog-ng-core \
	supervisor \
	&& rm -rf /var/lib/apt/lists/* \
	&& touch /etc/default/locale 

COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY syslog-ng.conf /etc/syslog-ng/syslog-ng.conf
COPY fetch_accounts.pl /usr/local/bin/
COPY postfix.conf /etc/postfix/main.cf
COPY envparser.sh /root/

RUN echo 'MAILTO=""' > /etc/cron.d/fetch_accounts && echo '* * * * *   root   . /root/env.sh; /usr/local/bin/fetch_accounts.pl >/dev/null 2>&1' >> /etc/cron.d/fetch_accounts

EXPOSE 25

CMD exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf

RUN rm -rf /tmp/* /var/tmp/*
