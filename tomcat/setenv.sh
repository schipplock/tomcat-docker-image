#!/bin/sh
export JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStore=/opt/tomcat/conf/cacerts.jks -Djavax.net.ssl.trustStorePassword=$(cat $TRUSTSTORE_PASSWORD_FILE)"

if [ "${REMOTE_DEBUG_ENABLED}" = "true" ]; then
  export JAVA_OPTS="${JAVA_OPTS} -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=0.0.0.0:8000"
fi
