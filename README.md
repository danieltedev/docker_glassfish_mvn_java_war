
# GlassFish Docker Setup with Maven

Este repositório contém um exemplo de configuração de um contêiner Docker para rodar o GlassFish 4, executar um projeto Java utilizando Maven e disponibilizar uma aplicação RESTful no servidor GlassFish. O projeto utiliza o exemplo de aplicação [simple-rest-war](https://github.com/joshelser/simple-rest-war/tree/master) como base para a construção da aplicação.

## Estrutura do Repositório

A estrutura do repositório é a seguinte:

```
glassfish_teste/
├── simple-rest-war/        # Projeto de exemplo simples RESTful
├── docker-compose.yml      # Arquivo para orquestrar os contêineres Docker
└── Dockerfile              # Arquivo de configuração para a criação da imagem Docker
```

### `simple-rest-war`

Este diretório contém um exemplo de projeto Java que será construído e implantado no GlassFish. O código-fonte está localizado em `simple-rest-war/src` e o arquivo `pom.xml` define as dependências do Maven para o projeto.

### `docker-compose.yml`

Este arquivo é responsável por configurar e orquestrar o contêiner Docker para rodar o GlassFish e o Maven, além de mapear as portas para acessibilidade externa.

```yaml
version: "3.8"
services:
  app:
    build: .
    ports:
      - "8080:8080"      # Porta para acessar a aplicação
      - "4848:4848"      # Porta para o console administrativo do GlassFish
      - "8181:8181"      # Porta alternativa para o GlassFish
    working_dir: /usr/src/app  # Diretório de trabalho dentro do contêiner
```

### `Dockerfile`

O arquivo `Dockerfile` define a imagem Docker que será criada. Ele instala o Maven e o GlassFish, configura o servidor e executa o processo de construção do projeto.

```dockerfile
FROM openjdk:8-jdk

# Instala o Maven e o Bash
RUN apt-get update && apt-get install -y maven && apt-get install -y bash

# Definir a versão do GlassFish e o diretório de instalação
ENV GLASSFISH_VERSION 4.1.2
ENV GLASSFISH_HOME /opt/glassfish4

# Baixar e instalar o GlassFish
RUN wget -q http://download.oracle.com/glassfish/$GLASSFISH_VERSION/release/glassfish-$GLASSFISH_VERSION.zip &&     unzip glassfish-$GLASSFISH_VERSION.zip -d /opt &&     rm glassfish-$GLASSFISH_VERSION.zip

# Configurar a senha do administrador
RUN echo "AS_ADMIN_PASSWORD=" > /tmp/glassfish_pwd &&     echo "AS_ADMIN_NEWPASSWORD=adminpassword" >> /tmp/glassfish_pwd &&     $GLASSFISH_HOME/bin/asadmin start-domain &&     sleep 10 &&     $GLASSFISH_HOME/bin/asadmin --user admin --passwordfile=/tmp/glassfish_pwd change-admin-password &&     rm /tmp/glassfish_pwd

# Habilitar Secure Admin
RUN echo "AS_ADMIN_PASSWORD=adminpassword" > /tmp/glassfish_pwd &&     $GLASSFISH_HOME/bin/asadmin start-domain &&     sleep 10 &&     $GLASSFISH_HOME/bin/asadmin --user admin --passwordfile=/tmp/glassfish_pwd enable-secure-admin &&     rm /tmp/glassfish_pwd &&     $GLASSFISH_HOME/bin/asadmin stop-domain

# Expor as portas padrão do GlassFish
EXPOSE 4848 8080 8181

# Adicionar o Maven e o GlassFish ao PATH
ENV PATH="$PATH:$MAVEN_HOME/bin:$GLASSFISH_HOME/bin"

# Definir o diretório de trabalho
WORKDIR /usr/src/app

# Copiar os arquivos do projeto
COPY ./simple-rest-war/pom.xml .
COPY ./simple-rest-war/src ./src

# Executar o Maven para gerar o WAR
RUN mvn clean package -DskipTests

# Copiar o WAR gerado para o diretório de autodeploy do GlassFish
RUN cp target/*.war $GLASSFISH_HOME/glassfish/domains/domain1/autodeploy/

# Comando para iniciar o GlassFish
CMD ["asadmin", "start-domain", "--verbose"]
```

## Como Usar

### Pré-requisitos

Antes de começar, certifique-se de ter o [Docker](https://www.docker.com/products/docker-desktop) e o [Docker Compose](https://docs.docker.com/compose/install/) instalados na sua máquina.

### Passo 1: Clonar o Repositório

Clone este repositório em seu computador:

```bash
git clone https://github.com/joshelser/simple-rest-war.git
```

### Passo 2: Build da Imagem Docker

Acesse o diretório `glassfish_teste` onde estão localizados o `Dockerfile` e o `docker-compose.yml`. Em seguida, execute o comando para construir e iniciar os contêineres:

```bash
docker-compose up --build
```

Este comando irá:
- Construir a imagem do Docker utilizando o `Dockerfile` e instalar o GlassFish e Maven.
- Iniciar o contêiner com as configurações do `docker-compose.yml`.

### Passo 3: Acessar a Aplicação

Após o contêiner estar em execução, você pode acessar a aplicação através do navegador:

- **Aplicação Web**: [http://localhost:8080](http://localhost:8080)
- **Console Administrativo do GlassFish**: [http://localhost:4848](http://localhost:4848)

### Passo 4: Verificar os Logs

Para visualizar os logs do contêiner em execução:

```bash
docker-compose logs -f
```

### Passo 5: Parar e Remover os Contêineres

Para parar e remover os contêineres:

```bash
docker-compose down
```

## Problemas Conhecidos

- **Erro de "Port already allocated"**: Caso o contêiner não consiga alocar uma porta, verifique se a porta não está sendo usada por outro processo na sua máquina.
  
- **Problemas com o WAR não sendo gerado**: Se o WAR não estiver sendo gerado corretamente, execute manualmente `mvn clean package` dentro do contêiner para verificar erros de build.

## Licença

Este projeto está licenciado sob a [MIT License](LICENSE).
