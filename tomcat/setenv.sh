#!/bin/sh
export JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStore=/opt/tomcat/conf/cacerts.jks -Djavax.net.ssl.trustStorePassword=$(cat $TRUSTSTORE_PASSWORD_FILE)"

if [ "${REMOTE_DEBUG_ENABLED}" = "true" ]; then
  export JAVA_OPTS="${JAVA_OPTS} -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=0.0.0.0:8000"
fi

if [ "${REMOTE_JMX_ENABLED}" = "true" ]; then
  export JAVA_OPTS="${JAVA_OPTS} -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9000 -Dcom.sun.management.jmxremote.rmi.port=9100 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Djava.rmi.server.hostname=0.0.0.0"
fi
