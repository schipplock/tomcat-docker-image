FROM ubuntu:22.04 as build
SHELL ["/bin/bash", "-c"]

ARG APR_VERSION=1.7.4
ARG TOMCAT_VERSION=10.1.17
ARG TOMCAT_NATIVE_VERSION=2.0.6

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/opt/jdk
ENV PATH=/opt/jdk/bin:/opt/ant/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Falls der Ubuntu-Server mal wieder rumspackt (tut er manchmal),
# kann man hier einen Mirror eintragen
COPY ubuntu/sources.list /etc/apt/sources.list

COPY tomcat/build.properties build/tomcat/build.properties
COPY tomcat/tomcat-environment-property-source-file-0.0.1.jar /extensions/tomcat-environment-property-source-file.jar
COPY tomcat/jakarta.el-api-5.0.1.jar /extensions/jakarta.el-api-5.0.1.jar
COPY tomcat/jakarta.servlet.jsp.jstl-api-3.0.0.jar /extensions/jakarta.servlet.jsp.jstl-api-3.0.0.jar
COPY tomcat/jakarta.servlet.jsp.jstl-3.0.1.jar /extensions/jakarta.servlet.jsp.jstl-3.0.1.jar
COPY tomcat/tomcat-owb-4.0.1.jar /extensions/tomcat-owb-4.0.1.jar
COPY tomcat/postgresql-42.7.1.jar /libs/postgresql.jar
COPY tomcat/catalina.properties /configurations/catalina.properties
COPY tomcat/logging.properties /configurations/logging.properties
COPY tomcat/server.xml /configurations/server.xml
COPY tomcat/context.xml /configurations/context.xml
COPY tomcat/tomcat-users.xml /configurations/tomcat-users.xml
COPY tomcat/keystore.jks /configurations/keystore.jks
COPY tomcat/cacerts.jks /configurations/cacerts.jks
COPY tomcat/setenv.sh /configurations/setenv.sh

RUN apt-get update && apt-get install -y \
  build-essential libssl-dev \
  wget nano unzip

RUN mkdir -p /opt/jdk \
 && wget --no-check-certificate "https://download.bell-sw.com/java/21.0.1+12/bellsoft-jdk21.0.1+12-linux-amd64-lite.tar.gz" \
 && tar xf bellsoft-jdk21.0.1+12-linux-amd64-lite.tar.gz -C /opt/jdk --strip-components=1

RUN mkdir -p /opt/ant \
 && wget --no-check-certificate "https://dlcdn.apache.org//ant/binaries/apache-ant-1.10.14-bin.tar.gz" \
 && tar xf apache-ant-1.10.14-bin.tar.gz -C /opt/ant --strip-components=1

RUN mkdir -p build/apr \
 && wget https://downloads.apache.org/apr/apr-$APR_VERSION.tar.gz \
 && tar xf apr-$APR_VERSION.tar.gz -C build/apr --strip-components=1 \
 && cd build/apr \
 && ./configure --prefix=/usr \
 && make DESTDIR=/opt/apr install \
 && make install \
 && cd /

RUN mkdir -p build/tomcat_native \
 && wget https://dlcdn.apache.org/tomcat/tomcat-connectors/native/$TOMCAT_NATIVE_VERSION/source/tomcat-native-$TOMCAT_NATIVE_VERSION-src.tar.gz \
 && tar xf tomcat-native-$TOMCAT_NATIVE_VERSION-src.tar.gz -C build/tomcat_native --strip-components=1 \
 && cd build/tomcat_native/native \
 && export JAVA_HOME=$(java -XshowSettings:properties -version 2>&1 > /dev/null | grep 'java.home' | awk '{print $3}') \
 && ./configure --prefix=/usr \
 && make DESTDIR=/opt/tomcat_native install \
 && make install \
 && cd /

RUN mkdir -p build/tomcat \
 && export SOURCE_DATE_EPOCH=$(date +%s) \
 && wget https://dlcdn.apache.org/tomcat/tomcat-10/v$TOMCAT_VERSION/src/apache-tomcat-$TOMCAT_VERSION-src.tar.gz \
 && tar xf apache-tomcat-$TOMCAT_VERSION-src.tar.gz -C build/tomcat --strip-components=1 \
 && cd build/tomcat \
 && sed -i 's/<property name="compile.release" value="11"\/>/<property name="compile.release" value="21"\/>/' build.xml \
 && sed -i 's/<property name="min.java.version" value="11"\/>/<property name="min.java.version" value="21"\/>/' build.xml \
 && sed -i 's/<property name="build.java.version" value="11"\/>/<property name="build.java.version" value="21"\/>/' build.xml \
 && ant && mkdir -p /opt/tomcat \
 && cp -R output/build/* /opt/tomcat/ \
 && cp /extensions/tomcat-environment-property-source-file.jar /opt/tomcat/lib/ \
 && cp /extensions/jakarta.el-api-5.0.1.jar /opt/tomcat/lib/ \
 && cp /extensions/jakarta.servlet.jsp.jstl-api-3.0.0.jar /opt/tomcat/lib/ \
 && cp /extensions/jakarta.servlet.jsp.jstl-3.0.1.jar /opt/tomcat/lib/ \
 && cp /extensions/tomcat-owb-4.0.1.jar /opt/tomcat/lib/ \
 && cp /libs/postgresql.jar /opt/tomcat/lib/ \
 && cp /configurations/catalina.properties /opt/tomcat/conf/ \
 && cp /configurations/logging.properties /opt/tomcat/conf/ \
 && cp /configurations/server.xml /opt/tomcat/conf/ \
 && cp /configurations/context.xml /opt/tomcat/conf/ \
 && cp /configurations/tomcat-users.xml /opt/tomcat/conf/ \
 && cp /configurations/keystore.jks /opt/tomcat/conf/ \
 && cp /configurations/cacerts.jks /opt/tomcat/conf/ \
 && cp /configurations/setenv.sh /opt/tomcat/bin/ && chmod +x /opt/tomcat/bin/setenv.sh \
 && mkdir -p /opt/tomcat/uploads \
 && rm -rf /opt/tomcat/webapps/{examples,docs,manager,host-manager,ROOT,webapps-javaee}

RUN mkdir -p /opt/java \
 && wget --no-check-certificate "https://download.bell-sw.com/java/21.0.1+12/bellsoft-jre21.0.1+12-linux-amd64.tar.gz" \
 && tar xf bellsoft-jre21.0.1+12-linux-amd64.tar.gz -C /opt/java --strip-components=1 \
 && rm -rf /opt/java/{man,legal}

FROM ubuntu:22.04
SHELL ["/bin/bash", "-c"]

ENV LANG=de_DE.utf8
ENV TZ=Europe/Berlin
ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/opt/java
ENV TOMCAT_UPLOAD_DIR=/opt/tomcat/uploads
ENV REMOTE_DEBUG_ENABLED=false
ENV PATH=/opt/java/bin:/opt/tomcat/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

COPY --from=build /opt/java /opt/java
COPY --from=build /opt/apr/usr /usr
COPY --from=build /opt/tomcat_native/usr /usr
COPY --from=build /opt/tomcat /opt/tomcat

RUN apt-get update && apt-get install -y \
  locales tzdata libssl3 nano \
 && locale-gen ${LANG} \
 && update-locale LANG=${LANG} \
 && cp -vf /usr/share/zoneinfo/${TZ} /etc/localtime \
 && echo ${TZ} | tee /etc/timezone \
 && dpkg-reconfigure --frontend noninteractive tzdata \
 && addgroup --gid 1000 tomcat \
 && adduser --system --uid 1000 --no-create-home --shell /bin/bash --home "/opt/tomcat" --gecos "" --ingroup tomcat tomcat \
 && echo tomcat:tomcat | chpasswd \
 && ln -sf /proc/1/fd/1 /opt/tomcat/logs/access_log \
 && chown -R tomcat:tomcat /opt/tomcat \
 && rm -rf /var/lib/apt/lists/* \
 && true

USER tomcat
WORKDIR /opt/tomcat
CMD ["catalina.sh", "run"]