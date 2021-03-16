FROM jboss/wildfly:22.0.1.Final

# variables
ENV MAVEN_REPOSITORY                https://repo1.maven.org/maven2

ENV MYSQL_CONNECTOR_VERSION         8.0.21
ENV MYSQL_CONNECTOR_DOWNLOAD_URL    ${MAVEN_REPOSITORY}/mysql/mysql-connector-java/${MYSQL_CONNECTOR_VERSION}/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar
ENV MYSQL_CONNECTOR_SHA256          2f62d886270a75ebc8e8fd89127d4a30ccc711f02256ade2cfb7090817132003

ENV ECLIPSELINK_VERSION             2.7.7
ENV ECLIPSELINK_DOWNLOAD_URL        ${MAVEN_REPOSITORY}/org/eclipse/persistence/eclipselink/${ECLIPSELINK_VERSION}/eclipselink-${ECLIPSELINK_VERSION}.jar
ENV ECLIPSELINK_PATH                modules/system/layers/base/org/eclipse/persistence/main
ENV ECLIPSELINK_SHA256              5225a9862205612c76f10259fce17241f264619fba299a5fd345cd950e038254

ENV WILDFLY_HOME                    /opt/jboss/wildfly
ENV WILDFLY_USER                    admin
ENV WILDFLY_PASS                    secret
ENV JBOSS_CLI                       ${WILDFLY_HOME}/bin/jboss-cli.sh
ENV DEBUGGING                       false

# create folders and permissions
USER root

COPY ./jwt.keystore ${WILDFLY_HOME}/standalone/configuration/
COPY ./configure-elytron.cli ${WILDFLY_HOME}/bin/
COPY entrypoint.sh /opt/entrypoint.sh



RUN echo ">  1. install mysql-connector" && \
    curl -Lso mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar ${MYSQL_CONNECTOR_DOWNLOAD_URL} && \
    (sha256sum mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar | grep ${MYSQL_CONNECTOR_SHA256} > /dev/null|| (>&2 echo "sha256sum failed $(sha256sum mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar)" && exit 1)) && \
    \
    echo ">  2. install eclipselink" && \
    curl -Lso ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar ${ECLIPSELINK_DOWNLOAD_URL} && \
    (sha256sum ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar | grep ${ECLIPSELINK_SHA256} > /dev/null|| (>&2 echo "sha256sum failed $(sha256sum ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/eclipselink-${ECLIPSELINK_VERSION}.jar)" && exit 1)) && \
    sed -i "s/<\/resources>/\n\
    <resource-root path=\"eclipselink-${ECLIPSELINK_VERSION}.jar\">\n \
    <filter>\n \
    <exclude path=\"javax\/**\" \/>\n \
    <\/filter>\n \
    <\/resource-root>\n \
    <\/resources>/" ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/module.xml && \
    sed -i "s/<\/dependencies>/\
    <module name=\"javax.ws.rs.api\"\/>\n\
    <module name=\"javax.json.api\"\/>\n\
    <\/dependencies>/" ${WILDFLY_HOME}/${ECLIPSELINK_PATH}/module.xml && \
    chown -R jboss:jboss ${WILDFLY_HOME}/${ECLIPSELINK_PATH} && \
    \
    echo "> 3. prepare wildfly" && \
    (${WILDFLY_HOME}/bin/standalone.sh &) && \
    while [[ $(curl -sI http://localhost:8080 | head -n 1) != *"200"* ]]; do sleep 1; done ; \
    $JBOSS_CLI -c "module add --name=com.mysql --resources=/opt/jboss/mysql-connector-java-${MYSQL_CONNECTOR_VERSION}.jar --dependencies=javax.api\,javax.transaction.api" && \
    $JBOSS_CLI -c "/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql,driver-class-name=com.mysql.cj.jdbc.Driver)" && \
    \
    echo "> 4. setup access token" && \
    $JBOSS_CLI -c --file=${WILDFLY_HOME}/bin/configure-elytron.cli && \
    $JBOSS_CLI -c ":shutdown" && \
    \
    echo "> 5. temporary workaround" && \
    chown jboss -R wildfly/standalone
    

USER jboss

# ports
EXPOSE 8080 9990 8443 9993 8787

ENTRYPOINT ["/bin/bash", "/opt/entrypoint.sh"]