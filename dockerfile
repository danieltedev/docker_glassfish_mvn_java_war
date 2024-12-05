# Use uma imagem base com Java 8
FROM openjdk:8-jdk

# Instala o Maven
RUN apt-get update && apt-get install -y maven && apt-get install -y bash

# Define GlassFish 4
ENV GLASSFISH_VERSION 4.1.2
ENV GLASSFISH_HOME /opt/glassfish4
# ENV MAVEN_VERSION 3.9.5
# ENV MAVEN_HOME /opt/maven

# Baixa e instala o GlassFish
RUN wget -q http://download.oracle.com/glassfish/$GLASSFISH_VERSION/release/glassfish-$GLASSFISH_VERSION.zip && \
    unzip glassfish-$GLASSFISH_VERSION.zip -d /opt && \
    rm glassfish-$GLASSFISH_VERSION.zip
    # wget https://dlcdn.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.zip && \
    # unzip apache-maven-$MAVEN_VERSION-bin.zip -d /opt && \
    # rm apache-maven-$MAVEN_VERSION-bin.zip && \
    # ln -s /opt/apache-maven-$MAVEN_VERSION /opt/maven && \
    # apt-get clean

# Configurar a senha do administrador
RUN echo "AS_ADMIN_PASSWORD=" > /tmp/glassfish_pwd && \
    echo "AS_ADMIN_NEWPASSWORD=adminpassword" >> /tmp/glassfish_pwd && \
    $GLASSFISH_HOME/bin/asadmin start-domain && \
    sleep 10 && \
    $GLASSFISH_HOME/bin/asadmin --user admin --passwordfile=/tmp/glassfish_pwd change-admin-password && \
    rm /tmp/glassfish_pwd

# Habilitar o Secure Admin
RUN echo "AS_ADMIN_PASSWORD=adminpassword" > /tmp/glassfish_pwd && \
    $GLASSFISH_HOME/bin/asadmin start-domain && \
    sleep 10 && \
    $GLASSFISH_HOME/bin/asadmin --user admin --passwordfile=/tmp/glassfish_pwd enable-secure-admin && \
    rm /tmp/glassfish_pwd && \
    $GLASSFISH_HOME/bin/asadmin stop-domain

# Exponha as portas padrão do GlassFish
EXPOSE 4848 8080 8181

# Adicionar o Maven e GlassFish ao PATH
ENV PATH="$PATH:$MAVEN_HOME/bin:$GLASSFISH_HOME/bin"

# Diretório de trabalho para o Maven
WORKDIR /usr/src/app

COPY ./simple-rest-war/pom.xml .
COPY ./simple-rest-war/src ./src
# COPY simple-rest-war/src /usr/src/app/src
# COPY simple-rest-war/pom.xml /usr/src/app/pom.xml

RUN mvn clean package -DskipTests

RUN cp target/*.war $GLASSFISH_HOME/glassfish/domains/domain1/autodeploy/

# Define o comando padrão para iniciar o GlassFish
CMD ["asadmin", "start-domain", "--verbose"]
