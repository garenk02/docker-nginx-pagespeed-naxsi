FROM ubuntu:16.04

MAINTAINER Alexander Kusakin <alexander.a.kusakin@gmail.com>

ENV NPS_VERSION 1.11.33.4
ENV NGINX_VERSION 1.11.4
ENV NAXSI_VERSION 0.54

ENV OPENSSL_VERSION 1.1.0a
ENV ZLIB_VERSION 1.2.8
ENV PCRE_VERSION 8.39

RUN apt-get update \
  && apt-get build-dep --no-install-recommends -y nginx \
  && apt-get install --no-install-recommends wget unzip -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir ~/custom-nginx \
  && cd ~/custom-nginx \
  && wget --no-check-certificate https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz \
  && wget --no-check-certificate http://zlib.net/zlib-${ZLIB_VERSION}.tar.gz \
  && wget --no-check-certificate ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-${PCRE_VERSION}.tar.bz2 \
  && wget --no-check-certificate https://github.com/nbs-system/naxsi/archive/${NAXSI_VERSION}.tar.gz \
  && wget --no-check-certificate http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
  && wget --no-check-certificate https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.zip -O release-${NPS_VERSION}-beta.zip \
  && unzip release-${NPS_VERSION}-beta.zip && rm release-${NPS_VERSION}-beta.zip \
  && cd ngx_pagespeed-release-${NPS_VERSION}-beta && wget --no-check-certificate https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz \
  && tar -xzvf ${NPS_VERSION}.tar.gz && rm ${NPS_VERSION}.tar.gz && cd ~/custom-nginx \
  && tar -xvf openssl-${OPENSSL_VERSION}.tar.gz && rm openssl-${OPENSSL_VERSION}.tar.gz \
  && tar -xvf zlib-${ZLIB_VERSION}.tar.gz && rm zlib-${ZLIB_VERSION}.tar.gz \
  && tar xvf pcre-${PCRE_VERSION}.tar.bz2 && rm pcre-${PCRE_VERSION}.tar.bz2 \
  && tar -xvzf ${NAXSI_VERSION}.tar.gz && rm ${NAXSI_VERSION}.tar.gz \
  && tar -xvzf nginx-${NGINX_VERSION}.tar.gz && rm nginx-${NGINX_VERSION}.tar.gz \
  && cd nginx-${NGINX_VERSION} \
  && ./configure \
        --prefix=/usr/share/nginx \
        --with-cc-opt='-g -O3 -flto -pipe -fwhole-program -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -D_FORTIFY_SOURCE=2' \
        --with-ld-opt='-g -O3 -flto -pipe -fwhole-program -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -D_FORTIFY_SOURCE=2 -Wall -Wl,-Bsymbolic-functions -Wl,-z,relro' \
        --add-module=../ngx_pagespeed-release-${NPS_VERSION}-beta ${PS_NGX_EXTRA_FLAGS} \
        --add-module=../naxsi-${NAXSI_VERSION}/naxsi_src/ \
        --with-zlib=../zlib-${ZLIB_VERSION} \
        --with-openssl=../openssl-${OPENSSL_VERSION} \
        --with-pcre=../pcre-${PCRE_VERSION} \
        --with-pcre-jit \
        --with-http_gzip_static_module \
        --with-http_realip_module \
        --with-http_ssl_module \
        --with-http_v2_module \
        --without-mail_pop3_module \
        --without-mail_smtp_module \
        --without-mail_imap_module \
        --user=www-data \
        --group=www-data \
        --conf-path=/etc/nginx/nginx.conf \
        --http-log-path=/var/log/nginx/access.log \
        --error-log-path=/var/log/nginx/error.log \
        --lock-path=/var/lock/nginx.lock \
        --pid-path=/run/nginx.pid \
  && make -j`nproc` \
  && make install \
  && cd ~/custom-nginx \
  && mkdir -p /etc/nginx/ \
  && mkdir -p /var/log/nginx/ \
  && cp naxsi-$NAXSI_VERSION/naxsi_config/naxsi_core.rules /etc/nginx/naxsi_core.rules \
  && rm -rf ~/custom-nginx

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443

VOLUME /etc/nginx /var/www

CMD ["/usr/share/nginx/sbin/nginx", "-g", "daemon off;"]
