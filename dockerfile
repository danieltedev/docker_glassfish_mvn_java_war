FROM openjdk:8-jdk

RUN apt-get update && apt-get install -y maven && apt-get install -y bash

ENV GLASSFISH_VERSION 4.1.2
ENV GLASSFISH_HOME /opt/glassfish4

RUN wget -q http://download.oracle.com/glassfish/$GLASSFISH_VERSION/release/glassfish-$GLASSFISH_VERSION.zip && \
    unzip glassfish-$GLASSFISH_VERSION.zip -d /opt && \
    rm glassfish-$GLASSFISH_VERSION.zip

RUN echo "AS_ADMIN_PASSWORD=" > /tmp/glassfish_pwd && \
    echo "AS_ADMIN_NEWPASSWORD=adminpassword" >> /tmp/glassfish_pwd && \
    $GLASSFISH_HOME/bin/asadmin start-domain && \
    sleep 10 && \
    $GLASSFISH_HOME/bin/asadmin --user admin --passwordfile=/tmp/glassfish_pwd change-admin-password && \
    rm /tmp/glassfish_pwd

RUN echo "AS_ADMIN_PASSWORD=adminpassword" > /tmp/glassfish_pwd && \
    $GLASSFISH_HOME/bin/asadmin start-domain && \
    sleep 10 && \
    $GLASSFISH_HOME/bin/asadmin --user admin --passwordfile=/tmp/glassfish_pwd enable-secure-admin && \
    rm /tmp/glassfish_pwd && \
    $GLASSFISH_HOME/bin/asadmin stop-domain

EXPOSE 4848 8080 8181

ENV PATH="$PATH:$MAVEN_HOME/bin:$GLASSFISH_HOME/bin"

WORKDIR /usr/src/app

COPY ./simple-rest-war/pom.xml .
COPY ./simple-rest-war/src ./src

RUN mvn clean package -DskipTests

RUN cp target/*.war $GLASSFISH_HOME/glassfish/domains/domain1/autodeploy/

CMD ["asadmin", "start-domain", "--verbose"]
