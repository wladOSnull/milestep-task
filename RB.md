# Runbook

This is DevOps runbook for test task.

## DevOps Test Task
> Task:
> Deploy application and describe process in document.
> 
> Conditions:
> - Deploy opensource application Lavagna in your local machine (https://github.com/digitalfondue/lavagna );
> - Launch application in production mode;
> - Dockerize application;
> - Describe your deploying process in document.  
>
> Optional (advanced):
> - Use PostgreSQL, MySQL, or MariaDB as database;
> - Use docker-compose to orchestrate application;
> - Describe your deploying process in document.

---

## Environment prepare

### Server + connection

- install VM Box
- get some VM image, in my case *Ubuntu Server 20.04.4 Focal Fossa* -> [osboxes.org](https://www.osboxes.org/ubuntu-server/)
- **deploy or add** the image and run it
- update/upgrade the system
- establish connection to the server from working Linux by SSH
    - install **openssh-server** on server + check **ufw** rules for port accessing
    - try to reach to server with **ping, nc, telnet ...**
    - connect to server via **ssh** by password
    - use now **scp** for providing *.pub* key
    - connect to server now with **ssh** by key

P.s.: all "manipulation" with server will be performed now from "host" terminal

### Maven

Install **Maven** (bacause of Java lang and Maven-way in *Lavagna* project). Also Maven needs JDK as well, but for the project recommend is 1.8 version (actually Maven cannot even build Lavagna with opendjdk-11 for example).

- Java installing 

    ```sh
    # installig & checking version of git
    ~ sudo apt install openjdk-8-jdk
    ~ java -version
    
    # creating symlink for future version managing
    ~ sudo ln -s /usr/lib/jvm/java-8-openjdk-amd64 /usr/lib/jvm/default-java
    ```

- Maven installing

    ```sh
    # download the last version of Maven from official site
    ~ wget https://dlcdn.apache.org/maven/maven-...

    # unpack/install with sym-link for version managing
    ~ sudo tar xf apache-maven-*.tar.gz -C /opt
    ~ sudo ln -s /opt/apache-maven-?.?.?/ /opt/maven

    # provide system vars manually or create small bash script
    ~ export JAVA_HOME=/usr/lib/jvm/default-java
    ~ export M2_HOME=/opt/maven
    ~ export MAVEN_HOME=/opt/maven
    ~ export PATH=${M2_HOME}/bin:${PATH}

    # check Maven
    ~ mvn -v
    ```

    - ***OPTIONALLY:*** use this tutorial for Maven CLI autocompletion -> [github](https://github.com/juven/maven-bash-completion)

## Lavagna

- get the **Lavagna** project and build it

    ```sh
    ~ git clone https://github.com/digitalfondue/lavagna
    ~ cd lavagna
    ~ mvn install

    # check the artefacts, there must be 'lavagna.war' and 'lavagna-jetty-console.war'
    ~ ls -la ./target
    ```

## Tomcat

Install **Tomcat 9** server (bacause of *.war* artefact of **Lavagna** project; also 9 version, because 10v has some problem with old servlet applications)

- preparation to Tomcat

    ```sh
    # add new user for Tomcat
    ~ sudo useradd -m -U -d /opt/tomcat -s /bin/false tomcat
    ```

- download and install **Tomcat 9**  
    
    ```sh
    ~ wget https://dlcdn.apache.org/tomcat/tomcat-9/v9....
    ~ sudo tar -xf /tmp/apache-tomcat-... -C /opt
    ~ sudo ln -s /opt/tomcat/apache-tomcat-... /opt/tomcat
    ~ sudo chown -R tomcat: /opt/tomcat
    ~ sudo sh -c 'chmod +x /opt/tomcat/bin/*.sh'
    ```

- create **systemd** unit for **Tomcat**

    ```sh
    # add .service file for managing tomcat via systemctl
    ~ sudo vi /etc/systemd/system/tomcat.service
    ```
    
    ```ini
    [Unit]
    Description=Tomcat 9 servlet container
    After=network.target

    [Service]
    Type=forking

    User=tomcat
    Group=tomcat

    Environment="JAVA_HOME=/usr/lib/jvm/default-java"
    Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom -Djava.awt.headless=true"

    Environment="CATALINA_BASE=/opt/tomcat"
    Environment="CATALINA_HOME=/opt/tomcat"
    Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
    Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

    ExecStart=/opt/tomcat/bin/startup.sh
    ExecStop=/opt/tomcat/bin/shutdown.sh

    [Install]
    WantedBy=multi-user.target
    ```

    ```sh
    # inform systemd about new unit
    ~ sudo systemctl daemon-reload

    # add Tomcat to autostart
    ~ sudo systemctl enable --now tomcat

    # check status of Tomcat
    ~ sudo systemctl status tomcat
    ```

- check **ufw** rules (if necessary)

- try to connect from *host* web browser to **Tomcat** main page via http://server-ip:8080

## Lavagna + Tomcat + no DB + "dev" mode

- deploy artefact to **Tomcat**

    ```sh
    ~ sudo cp target/lavagna.war /opt/tomcat/webapps/
    ```

- check **Lavagna** service on http://server-ip:8080/lavagna - login/pass is *user*, as a result you have to see Lavagna UI in *dev* mode

    ![image](img/1.png?raw=true "Lavagna on 'local' machine")

## Lavagna + Tomcat + HSQLDB + "prod" mode

To see Lavagna app in *prod* mode, this artefact must be deployed with **-Dspring.profiles.active=prod** argument (and optionally the other *JVM* options like DB connector, login/pass... if there is need). For this case Tomcat have to use spicific *env* file for providing *JVM* options for it's contained *.war* applications.

- next steps provide the *JVM* options to Tomcat
    ```sh
    ~ sudo vi /opt/tomcat/bin/setenv.sh
    ```

    ```ini
    JAVA_OPTS="$JAVA_OPTS -Ddatasource.dialect=HSQLDB -Ddatasource.url=jdbc:hsqldb:mem:lavagna -Ddatasource.username=sa -Ddatasource.password= -Dspring.profiles.active=prod"
    ```

    ```sh
    ~ sudo chown tomcat: /opt/tomcat/bin/setenv.sh
    ~ sudo chmod +x /opt/tomcat/bin/setenv.sh
    ~ sudo systemctl restart tomcat.service
    ```

- or it can be defined in an external file (like the bundled *sample-conf.properties*) and define the following property

    ```ini
    JAVA_OPTS="$JAVA_OPTS -Dlavagna.config.location=file:/your/file/location.properties
    ```

- all possible variables and values can be found in 
    - "lavagna.sh" from this chapter ->  [github](https://github.com/digitalfondue/lavagna#for-testing-purposes)
    - "README_EXECUTABLE_WAR.txt" in main repo -> [github](https://github.com/digitalfondue/lavagna/blob/master/README_EXECUTABLE_WAR.txt)

- check **Lavagna** service on http://server-ip:8080/lavagna/, as a result you have to see Lavagna UI in *prod* mode, "setup" stage

    ![image](img/4.png?raw=true "Lavagna on 'server'")

## Lavagna + embedded Jetty + no DB + "dev" mode

In this case i have used artefact *lavagna-jetty-console.war* from *target/* folder buided by myself but deployed this one just on the "host" machine. I did not use any DBs in this case.

- deploy the project with using of embedded, by Maven plugin "jetty-console", applet container

    ```sh
    # in case of no DB command to eun is very simple
    ~ java -jar lavagna-jetty-console.war
    ```

- check **Lavagna** service on http://localhost:8080/, login/pass is *user*, as a result you have to see Lavagna UI in *dev* mode

    ![image](img/2.png?raw=true "Lavagna on 'local' machine")

## Lavagna + embedded Jetty + HSQLDB + "prod" mode

There is no need to install *HSQLDB* due to embedded version in Lavagna *.war* artefact. Difference between previous and current step is only more specific run command.

- deploy the project with using of embedded applet container and DB (by Maven plugin "jetty-console" and "hsqldb" dependency respectively)

    ```sh
    ~ java \
    	-Ddatasource.dialect=HSQLDB \
    	-Ddatasource.url=jdbc:hsqldb:mem:lavagna \
    	-Ddatasource.username=sa \
    	-Ddatasource.password= \
    	-Dspring.profiles.active=prod \
    	-jar lavagna-jetty-console.war
    ```

- check **Lavagna** service on http://localhost:8080/, as a result you have to see Lavagna UI in *prod* mode, "setup" stage

    ![image](img/3.png?raw=true "Lavagna on 'local' machine")

## Lavagna + embedded Jetty + PGSQL + "prod" mode

In this case application was runned on "host" machine in Jetty-embedded variant with PostgreSQL installed on "host" as well.

- configure PostgreSQL for Lavagna

    ```sh
    ~ sudo -i -U postgres
    ~ psql
    ```

    ```sql
    /*
    * beside of usual user-db creation there have to be "unaccent"
    * extension, and all grants on functions for user
    */
    => CREATE USER lavagner WITH PASSWORD 'lava';
    => CREATE DATABASE lavagna WITH OWNER lavagner ENCODING 'UTF8';
    => GRANT ALL PRIVILEGES ON DATABASE lavagna TO lavagner;
    => \c lavagna
    => CREATE EXTENSION IF NOT EXISTS unaccent;
    => GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO lavagner;
    ```

- new PostgreSQL user must have access to DB by password, so

    ```sql
    /*
    * in psql to get path to pg_hba.conf
    */
    => SHOW hba_file;
    ```

    ```sh
    ~ sudo vi /path/to/pg_hba.conf
    ```

    ```ini
    local all postgres peer
    local lavagna lavagner md5
    ```

- run Lavagna project with new *JVM* options for PostgreSQL DB

    ```sh
    ~ java \
        -Ddatasource.dialect=PGSQL \
        -Ddatasource.url=jdbc:postgresql://localhost:5432/lavagna \
        -Ddatasource.username=lavagner \
        -Ddatasource.password=lava \
        -Dspring.profiles.active=prod \
        -jar lavagna-jetty-console.war
    ```

- check **Lavagna** service on http://localhost:8080/, as a result you have to see Lavagna UI in *prod* mode, "setup" stage

    ![image](img/5.png?raw=true "Lavagna on 'local' machine after restarting with persisted DB")

- and now after initialisation of Lavagna, creation some test board and restarting Lavagna app - data are persisted

## Lavagna + standalone Jetty + HSQLDB + "prod" mode

First of all there must be installed Jetty. For this purpose was used available "server" with Tomcat. Version of Jetty is not the last, because of problem with running old servlet (like Tomcat 10, so in this runbook was used Tomcat 9). In this case was used Jetty 9.4.48 version, due to researches of *pom.xml*, where 9.4.44 version is used.

- install Eclipse Jetty 9.4.48 from Eclipse site by official guide -> [eclipse.org](https://www.eclipse.org/jetty/documentation/jetty-9/index.html#quickstart-running-jetty)

- perform steps for *.war* deploy (just copy "lavagna.war" to "webapps" directory of Jetty)

- Jetty must be runned with specified port (8080 port conflict, due to Tomcat server), so

    - use *-Djetty.http.port=8081* Java option in command

        ```sh
        ~ java -jar start.jar \
            -Djetty.http.port=8081 \
            -Ddatasource.dialect=HSQLDB \
            -Ddatasource.url=jdbc:hsqldb:mem:lavagna \
            -Ddatasource.username=sa \
            -Ddatasource.password= \
            -Dspring.profiles.active=prod
        ```
    - or edit *jetty.http.port* entry in *http.ini* file (more detail in "Changing the Jetty Port" chapter -> [eclipse.org](https://www.eclipse.org/jetty/documentation/jetty-9/index.html#quickstart-common-config))

- check **Lavagna** service on http://server-ip:8081/, as a result you have to see Lavagna UI in *prod* mode, "setup" stage

    ![image](img/7.png?raw=true "Lavagna on 'server' machine with HSQLDB")

## Lavagna + Docker Jetty + no DB + "dev" mode

In this case Lavagna was runned in dockerized version of Jetty in very primitive way. Version of Jetty is not the last, because of problem with running old servlet (like Tomcat 10, so in this runbook was used Tomcat 9). Below is command for pulling Jetty 9.4.48 image, due to researches of *pom.xml*, where 9.4.44 version is used.

- get & run Jetty as docker image with the Lavagna app

    ```sh
    # get the specified version of Jetty
    ~ docker pull jetty:9.4.48-jdk8-openjdk
    
    # create container
    ~ docker create --name lavagna -p 80:8080 jetty:9.4.48-jdk8-openjdk
    
    # provide Lavagna to container
    ~ docker cp lavagna.war lavagna:/var/lib/jetty/webapps/ROOT.war

    # start the container
    ~ docker start lavagna
    ```

- check **Lavagna** service on http://localhost/, login/pass is user, as a result you have to see Lavagna UI in *dev* mode

    ![image](img/6.png?raw=true "Lavagna on 'local' machine in 'dev' mode")

## Lavagna + Docker Jetty + local PGSQL + "prod" mode

It is also possible to run the Lavagna project inside Jetty container but with connection to "local" or "host" Postgres DB. This DB was already created/initialized in ***Lavagna + embedded Jetty + PGSQL + "prod" mode*** chapter of this runbook.

- for this case Postgres must
    - either accept conection from other netwok - ***separate networks***
    - or container with Lavagna must share "host" network - ***shared network***

### Separate networks

- add to file *postgresql.conf*, in same directory with *pg_hna.conf*) new *listen_addresses* entry under comment

    ```sh
    ~ sudo vi /etc/postgresql/12/main/postgresql.conf
    ```

    ```ini
    #listen_addresses = 'localhost'         # what IP address(es) to listen on;
    listen_addresses = '*'
    ```

- get the Docker network addresses

    ```sh
    # there must be 'docker0' interface with 'inet' strings
    ~ ip address
    ```

- add new rules for connection to DB from Docker network with ipv4 and ipv6

    ```sh
    ~ sudo vi /path/to/pg_hba.conf
    ```

    ```ini
    host lavagna lavagner 172.16.0.0/12 md5
    ```

- restart Postgres

- run Jetty image with the Lavagna app, pay attention to ip private address of your "host" machine with installed Postgres in *-Ddatasource.url* argument (like 192.168.0.101 or 10.0.0.12 etc.)

    ```sh
    # create container
    ~ docker create \
        --name lavagna \
        -p 80:8080 \
        -e JAVA_OPTIONS="\
            -Ddatasource.dialect=PGSQL \
            -Ddatasource.url=jdbc:postgresql://private-ip-of-host:5432/lavagna \
            -Ddatasource.username=lavagner \
            -Ddatasource.password=lava \
            -Dspring.profiles.active=prod" \
        jetty:9.4.48-jdk8-openjdk

    # provide Lavagna to container
    ~ docker cp lavagna.war lavagna:/var/lib/jetty/webapps/ROOT.war

    # start the container
    ~ docker start lavagna
    ```

- check **Lavagna** service on http://localhost/, login/pass is user, as a result you have to see Lavagna UI in *prod* mode

    ![image](img/8.png?raw=true "Lavagna in Jetty container with old 'host' DB in 'prod' mode")

### Shared network

This case demands only slightly different command to run Docker image. Also used ports for container -> used port in "host" machine, so there is no need in *-p* binding now. IP address of Postgres DB is *localhost:5432*, due to common network for Postgres and container.

- run docker container with "localhost" address

    ```sh
    # create container and bind to Docker network with "host" type of driver, '-p' is redundant now
    ~ docker create \
        --name lavagna \
        --network=host \
        -e JAVA_OPTIONS="\
            -Ddatasource.dialect=PGSQL \
            -Ddatasource.url=jdbc:postgresql://localhost:5432/lavagna \
            -Ddatasource.username=lavagner \
            -Ddatasource.password=lava \
            -Dspring.profiles.active=prod" \
        jetty:9.4.48-jdk8-openjdk

    # provide Lavagna to container
    ~ docker cp lavagna.war lavagna:/var/lib/jetty/webapps/ROOT.war

    # start the container
    ~ docker start lavagna
    ```

- check **Lavagna** service on http://localhost:8080/, login/pass is user, as a result you have to see Lavagna UI in *prod* mode

    ![image](img/9.png?raw=true "Lavagna in Jetty container with old 'host' DB in 'prod' mode")

## Dockerization of the Lavagna

Lavanga can be used as Docker image (actually based on Jetty). For this purpose was written Dockerfile. Something was explored in official Docker Hub page of Jetty (small example of creating derived images), something borrowed from original Dockerfile of Jetty image (*ENTRYPOINT* and *CMD* for keeping trick of passing of the Java options).

[Dockerfile for the Lavanga app](./Dockerfile)

- place Dockerfile and *lavanga.war* in same directory (or edit path to artefact in *COPY* instruction)

- build image with specified tag by *-t* option

    ```sh
    ~ docker build -t lavagna .
    ```

- run image faster now

    ```sh
    ~ docker run \
        -d \
        --name lavagna \
        --network=host \
        -e JAVA_OPTIONS="\
            -Ddatasource.dialect=PGSQL \
            -Ddatasource.url=jdbc:postgresql://localhost:5432/lavagna \
            -Ddatasource.username=lavagner \
            -Ddatasource.password=lava \
            -Dspring.profiles.active=prod" \
        lavagna:latest
    ```

## Docker Compose + Lavagna + PostgreSQL

In this case the app and DB deployed by Docker Compose new gen - not the *docker-compose* but *docker compose* (without hyphen). This thing was installed like Docker extension from *apt* repository -> [docs.docker](https://docs.docker.com/compose/install/compose-plugin/#install-using-the-repository).

Due to requirements in README.md of the Lavagna - DB must be created with specified *character set* and *collation* -> [github](https://github.com/digitalfondue/lavagna#notes-about-databases)

- build *.war* artefact of the Lavagna of course

- create bash script for "post-configuration" of Postgres -> [script](./docker-compose/post_configuration.sh)

- create Dockerfile for new Postgres image -> [Dockerfile](./docker-compose/Dockerfile_postgres)
    - *COPY* instruction demands bash script in parent folder of Dockerfile

- create Dockerfile for Lavagna app -> [Dockerfile](./docker-compose/Dockerfile_lavagna)
    - *COPY* instruction demands artefact of Lavagna in parent folder of Dockerfile

- create Docker Compose file -> [docker-compose](./docker-compose/docker-compose-psql.yml)

    - Compose will create persistent volume, so app will save any changes between *start-stop* and even *up-down* commands

- for best practices Compose file needs also *.env* file with variables -> due to sensetive data and ".gitignore" it isn't included

- simple *up-down* are enough for running the Lavagna

    ```sh
    ~ docker compose -f docker-compose-psql.yaml up
    ```

- initialise the Lavagna and create some "project"  on http://localhost

- stop containers with *Ctrl+C* or *stop* (if *-d* options was used) or even kill them with *down* and rerun with *start* or *up*

- check **Lavagna** again on http://localhost/, as a result you have to see "old" data - available "admin" user and created Project

    ![image](img/10.png?raw=true "Lavagna + PSQL after re-up by Dockre Compose")

- simple proof that containers were recreated and data was not lost

    ![image](img/11.png?raw=true "Persistent volume is worked")

## Docker Compose + Lavagna + MySQL

Lavagna+MySQL variant of deploy share:
- *.war* artefact
- *Dockerfile* for the Lavagna
- *.env* file (MySQL variables are need to be added) 

Official page of Dockerized MySQL describe smart way to change some attributes/variables/sheets parameters by providing values to **musqld** -> [hub.docker](https://hub.docker.com/_/mysql#:~:text=Configuration%20without%20a%20cnf%20file). So in this case there is no need in Dockerfile for specific build of DB for the Lavagna. All options can be provided "on wheels" in Compose file.

- create Docker Compose file -> [docker-compose](./docker-compose/docker-compose-mysql.yml)

- add new variables for MySQL to *.env* file

- simple *up-down* are enough for running the Lavagna

    ```sh
    ~ docker compose -f docker-compose-mysql.yaml up
    ```

- initialise the Lavagna and create some "project"  on http://localhost:8080

- stop containers with *Ctrl+C* or *stop* (if *-d* options was used) or even kill them with *down* and rerun with *start* or *up*

- check **Lavagna** again on http://localhost:8080/, as a result you have to see "old" data - available "admin" user and created Project

    ![image](img/12.png?raw=true "Lavagna + PSQL after re-up by Dockre Compose")

- simple proof that containers were recreated and data was not lost

    ![image](img/13.png?raw=true "Persistent volume is worked")

## Lavagna as *.war* + S3 + Beanstalk

To deploy Lavagna in this time there must be AWS account.

- create AWS account or get access to available)

- create new **S3** bucket (default options + versioning)

- upload *.war* artefact

- create new **Beanstalk** service with Tomcat platform

    - upload "source code" from **S3** bucket, use "Copy URL" button for artefact in bucket

- wait couple of minute to deploying the Lavagna app

- check link to service

    ![image](img/14.png?raw=true "Lavagna app on the AWS Beanstalk")

## Dockerized Lavagna + ECR + Beanstalk

- create **ECR** repository "lavagna"

- perform recommend commands from "View push commands" in repository page for:
    - retrieving auth token
    
    ```sh
    ~ aws ecr get-login-password --profile milestep | docker login --username AWS --password-stdin 1234567890.dkr.ecr.region-1.amazonaws.com
    ```
    
    - buildng
    
    ```sh
    ~ docker build -t lavagna -f Dockerfile_lavagna .
    ```

    - tagging

    ```sh
    ~ docker tag lavagna:latest 1234567890.dkr.ecr.region-1.amazonaws.com/lavagna:latest
    ```

    - pushing

    ```sh
    ~ docker push 1234567890.dkr.ecr.region-1.amazonaws.com/lavagna:latest
    ```

- create deploy file -> [Dockerrun.aws.json](./aws/Dockerrun.aws.json)

- upload *Dockerrun.aws.json* to available **S3** bucket

- create new **Beanstalk** application

    - based on **"ECS running on 64bit Amazon Linux 2"** platforn branch

    - upload source origin code from **S3**

- check the app

    ![image](img/15.png?raw=true "dockerized Lavagna app on the AWS Beanstalk")