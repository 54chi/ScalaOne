# Alpine JRE: https://github.com/docker-library/openjdk/blob/4e39684901490c13eaef7892c44e39043d7c4bed/8-jdk/alpine/Dockerfile
# Alpine Scala from: https://github.com/flangelier/docker-scala/blob/master/2.12.1/8-jre/Dockerfile
# and https://hub.docker.com/r/hseeberger/scala-sbt/~/dockerfile/

FROM openjdk:8-jre-alpine

ENV SCALA_VERSION 2.12.1
ENV SBT_VERSION 0.13.13
ENV SBT_HOME /usr/local/sbt

# executes Java
RUN java -version 2>&1 | grep version | sed -e 's/^openjdk version /JAVA_VERSION=/' > $JAVA_HOME/release

# install wget, curl, tar, bash
RUN apk add --update wget tar curl bash && \
  rm -rf /var/cache/apk/*

# Install Scala
RUN \
  curl -fsL http://downloads.typesafe.com/scala/$SCALA_VERSION/scala-$SCALA_VERSION.tgz | tar xfz - -C /root/ && \
  echo >> /root/.bashrc && \
  echo 'export PATH=~/scala-$SCALA_VERSION/bin:$PATH' >> /root/.bashrc

# Install SBT
RUN \
  wget -q -O - "http://dl.bintray.com/sbt/native-packages/sbt/$SBT_VERSION/sbt-$SBT_VERSION.tgz" | gunzip | tar -x && \
  cp -a sbt-launcher-packaging-$SBT_VERSION/* /usr/local && rm -rf sbt-launcher-packaging-$SBT_VERSION && \
  echo -ne "- with sbt $SBT_VERSION\n" >> /root/.built

# Define working directory
WORKDIR /root


# Install Postgres
ENV PG_MAJOR 9.6
ENV PG_VERSION 9.6.2

ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH
ENV PGDATA /var/lib/postgresql/data

ENV LANG en_US.utf8

RUN apk update && apk add build-base readline-dev openssl-dev zlib-dev libxml2-dev glib-lang wget gnupg ca-certificates libssl1.0 && \
    gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
    gpg --list-keys --fingerprint --with-colons | sed -E -n -e 's/^fpr:::::::::([0-9A-F]+):$/\1:6:/p' | gpg --import-ownertrust && \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.7/gosu-amd64" && \
    wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.7/gosu-amd64.asc" && \
    gpg --verify /usr/local/bin/gosu.asc && \
    rm /usr/local/bin/gosu.asc && \
    chmod +x /usr/local/bin/gosu && \
    mkdir -p /docker-entrypoint-initdb.d && \
    wget ftp://ftp.postgresql.org/pub/source/v$PG_VERSION/postgresql-$PG_VERSION.tar.bz2 -O /tmp/postgresql-$PG_VERSION.tar.bz2 && \
    tar xvfj /tmp/postgresql-$PG_VERSION.tar.bz2 -C /tmp && \
    cd /tmp/postgresql-$PG_VERSION && ./configure --enable-integer-datetimes --enable-thread-safety --prefix=/usr/local --with-libedit-preferred --with-openssl  && make world && make install world && make -C contrib install && \
    cd /tmp/postgresql-$PG_VERSION/contrib && make && make install && \
    apk --purge del build-base openssl-dev zlib-dev libxml2-dev wget gnupg ca-certificates && \
    rm -r /tmp/postgresql-$PG_VERSION* /var/cache/apk/*

VOLUME /var/lib/postgresql/data


COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
RUN ["chmod", "+x", "/docker-entrypoint.sh"]

EXPOSE 5432
# CMD ["postgres"]
