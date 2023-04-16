#!/bin/bash
export JAVA_OPTS="$JAVA_OPTS -Djavax.net.ssl.trustStore=/opt/tomcat/conf/cacerts.jks -Djavax.net.ssl.trustStorePassword=$(cat $TRUSTSTORE_PASSWORD_FILE)"