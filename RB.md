# Mile Step

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
    - -> all "manipulation" with server will be performed now from "host" terminal

### Maven

Install **Maven** (bacause of Java lang and Maven-way in *Lavagna* project).

- install **jdk**

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

- all possible variables and values can be found in "lavagna.sh" from this chapter ->  [github](https://github.com/digitalfondue/lavagna#for-testing-purposes)

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
        -Dspring.profiles.active=dev \
        -jar lavagna-jetty-console.war
    ```

- check **Lavagna** service on http://localhost:8080/, as a result you have to see Lavagna UI in *prod* mode, "setup" stage

    ![image](img/5.png?raw=true "Lavagna on 'local' machine after restarting with persisted DB")

- and now after initialisation of Lavagna, creation some test board and restarting Lavagna app - data are persisted

## Lavagna + standalone Jetty + no DB + "prod" mode

First of all there must be installed Jetty. For this purpose was used available "server" with Tomcat.

- install Eclipse Jetty 11 from by official guide (quick start is enough) -> [eclipse.org](https://www.eclipse.org/jetty/documentation/jetty-11/operations-guide/index.html#og-quick-setup), do not forget to add all necessary modules - *server, http, deploy*

- Jetty must be runned with specified port (8080 port conflict, due to Tomcat server), so

    - use this command

        ```sh
        ~ sudo java -jar $JETTY_HOME/start.jar -Djetty.http.port=808
        ```
    - or edit *jetty.http.port* entry in *http.ini* file (more detail in next chapter -> [eclipse.org](https://www.eclipse.org/jetty/documentation/jetty-11/operations-guide/index.html#og-begin-start))