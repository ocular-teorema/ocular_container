FROM node:9.11 AS front

COPY ./src/ocular_front /node

RUN  cd /node \
  && rm -rf node_modules .git* *.lock package-lock.json \
  && npm i \
  && ./node_modules/gulp/bin/gulp.js production \
  && rm -rf node_modules .git* *.lock package-lock.json

FROM node:11.3 AS mobile

COPY ./src/ocular_front_mobile /node

RUN  cd /node \
  && rm -rf node_modules .git* *.lock package-lock.json \
  && npm i \
  && npm run build \
  && rm -rf node_modules .git* *.lock package-lock.json

FROM ubuntu:xenial AS build

RUN apt-get update \
 && apt-get install -y --fix-missing \
    ### Installing python3 with deps ###
    python3 python3-psycopg2 python3-pip virtualenv \
    ### Installing libsrtp0-dev ###
    libsrtp0-dev \
    ### QT deps ###
    qt5-default libqt5x11extras5-dev libqt5sql5-psql libqt5websockets5-dev \
    ### ffmpeg deps ###
    libx264-dev \
    ### Postgres ###
    postgresql \
    ### build deps ###
    cmake autotools-dev build-essential libtool automake pkg-config gengetopt yasm git \
    ### Nginx deps ###
    libpcre3-dev libssl-dev \
    ### qadrator deps ###
    libopencv-dev \
 && apt-get clean \
 && find /usr/ -type l -o -type f | sed 's/\ /\\\ /g ; s/usr/ocular\/usr/g' > /tmp/usr.lst

     ### ffmpeg ###
COPY ./src/FFmpeg /ocular/src/ffmpeg
RUN  cd /ocular/src/ffmpeg \
  && sh ./configure --prefix=/usr \
                    --enable-gpl \
                    --enable-nonfree \
                    --enable-libx264 \
                    --enable-pic \
                    --enable-shared \
                    --enable-static \
  && make -j8 \
  && make install

     ### Nginx ###
COPY ./src/nginx /ocular/src/nginx
RUN  cd /ocular/src/nginx \
  && sh ./configure --prefix=/usr/local/etc/nginx \
                    --sbin-path=/usr/local/sbin/nginx \
		    --conf-path=/usr/local/etc/nginx/nginx.conf \
		    --error-log-path=/var/log/nginx/error.log \
		    --http-log-path=/var/log/nginx/access.log \
		    --pid-path=/var/run/nginx.pid \
        	    --lock-path=/var/run/nginx.lock \
                    --with-cc-opt="-Wno-error" \
                    --with-http_ssl_module \
                    --add-module=${PWD}/nginx-rtmp-module-1.1.7 \
  && make \
  && make install

    ### processInstance ###
COPY ./src/ocular_pi /ocular/src/pi
COPY ./src/qhttpserver /ocular/src/pi/wrappers/qhttpserver
RUN  cd /ocular/src/pi \
  && qmake -r theoremG.pro \
  && make \
  && mv /ocular/src/pi/bin/processInstance /usr/bin/processInstance

    ### qadrator ###
COPY ./src/ocular_qadrator /ocular/src/qadrator
RUN  cd /ocular/src/qadrator/project \
  && qmake \
  && make \
  && mv /ocular/src/qadrator/project/kvadrator /usr/bin/kvadrator

    ### Admin Worker ###
COPY ./src/teorema /var/www/teorema
COPY --from=mobile /node/dist/teorema-mobile /var/www/teorema/mobile
COPY --from=front /node /var/www/teorema/theorema-frontend
RUN cd /var/www/teorema \
 && virtualenv -p python3 env \
 && . env/bin/activate \
 && pip3 install --no-cache-dir -r ./requirements.txt \
 && python3 manage.py collectstatic --noinput \
 && deactivate

FROM ubuntu:xenial AS diff

COPY --from=build /tmp/usr.lst /tmp/usr.lst
COPY --from=build /usr /ocular/usr
RUN cat /tmp/usr.lst | xargs rm -rf \
 && find /ocular/usr/ -empty -type d -delete

FROM ubuntu:xenial

RUN  apt-get update \
  && apt-get install -y --fix-missing \
     --no-install-recommends \
     ### Installing python3 with deps ###
     python3 python3-pip virtualenv cron \
     ### Postgres ###
     postgresql \
     ### Other deps ###
     supervisor rsync vim inotify-tools \
     ### libsrtp0-dev ###
     libsrtp0-dev \
     ### QT deps ###
     qt5-default libqt5x11extras5-dev libqt5sql5-psql libqt5websockets5-dev \
     ### ffmpeg deps ###
     libx264-dev \
     ### Nginx deps ###
     libpcre3-dev libssl-dev \
     ### qadrator deps ###
     libopencv-dev \
     ### ffmpeg ###
     ffmpeg \
     ### libsrtp ###
     libx264-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY --from=build /var/www/teorema /var/www/teorema
COPY --from=diff /ocular/usr /ocular/usr
RUN  rsync -azvh --remove-source-files /ocular/usr/ /usr/

    ### Other ###
COPY ./src/nginx/nginx-rtmp-module-1.1.7 /usr/local/lib/nginx/modules/nginx-rtmp-module-1.1.7
COPY ./src/supervisor /etc/supervisor
COPY ./src/scripts /usr/local/scripts
COPY ./src/pg /tmp/pg
RUN  mv /tmp/pg/pg_hba.conf /etc/postgresql/9.5/main/ \
     \
  && ln -sf /home/_processInstances/cameras.conf /etc/supervisor/conf.d/cameras.conf \
  && chgrp -R www-data /etc/supervisor/* \
  && chmod -R g+w /etc/supervisor/* \
  && mkdir -p /var/log/supervisor_child \
     \
  && chown -R www-data:www-data /var/www \
     \
  && groupadd nginx && useradd -g nginx nginx \
  && mkdir -p /var/log/nginx \
     \
  && mv /usr/local/scripts/crontab /var/spool/cron/crontabs/root \
  && chmod 755 /usr/local/scripts/* \
  && ln -sf /usr/local/scripts/docker_* /usr/bin/ \
     \
  && sed -i 's@Etc/UTC@Europe/Moscow@g' /etc/timezone \
  && sed -i 's@UTC0@MSK-3@g' /etc/localtime \
  && dpkg-reconfigure -f noninteractive tzdata

CMD ["docker_entrypoint"]

VOLUME /var/lib/postgresql/9.5/main /home/_processInstances /home/_VideoArchive
