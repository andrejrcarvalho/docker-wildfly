#!/bin/bash

echo "========================================================================="
if [ -z "${NO_ADMIN}" ]; then
    WILDFLY_PASS=${WILDFLY_PASS:-$(tr -cd "[:alnum:]" < /dev/urandom | head -c20)}
    ${WILDFLY_HOME}/bin/add-user.sh $WILDFLY_USER $WILDFLY_PASS && \
    echo "  You can configure this WildFly-Server using:" && \
    echo "  $WILDFLY_USER:$WILDFLY_PASS"
else
    echo "  You can NOT configure this WildFly-Server" && \
    echo "  because no admin-user was created."
fi
echo "========================================================================="
setup_db(){

    $DATASOURCE_EXISTS=$(cat ${WILDFLY_HOME}/standalone/configuration/standalone.xml | grep ${DB_NAME}DS)

    if [ -z "$DATASOURCE_EXISTS" ] && [ -n "$DB_NAME" ] && [ -n "$DB_USER" ] && [ -n "$DB_PASS" ]  && [ -n "$DB_HOST" ] && [ -n "$DB_PORT" ]; then

        echo "  Setting up the database..."

        while [[ $(curl -sI http://localhost:8080 | head -n 1) != *"200"* ]]; do sleep 1; done ;

        $JBOSS_CLI -c "data-source add \
            --name=${DB_NAME}DS \
            --jndi-name=java:/jdbc/datasources/${DB_NAME}DS \
            --user-name=$DB_USER \
            --password=$DB_PASS \
            --driver-name=mysql \
            --connection-url=jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME} \
            --use-ccm=false \
            --max-pool-size=25 \
            --blocking-timeout-wait-millis=5000 \
            --enabled=true"

        rm -f mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar

    fi
}

setup_db &

rm -rf ${WILDFLY_HOME}/standalone/configuration/standalone_xml_history/current/*

$WILDFLY_HOME/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0 $([ "$DEBUGGING" == "true" ] && echo "--debug *:8787")