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

## Lavagna + Tomcat

- deploy artefact to **Tomcat**

    ```sh
    ~ sudo cp target/lavagna.war /opt/tomcat/webapps/
    ```

- check **Lavagna** service on http://server-ip:8080/lavagna - login/pass is *user*, as a result you have to see UI like this one on screenshot

    ![image](img/1.png?raw=true "Lavagna on 'local' machine")

## Lavagna + embedded Jetty + no DB

In this case i have used artefact *lavagna-jetty-console.war* from *target/* folder buided by myself but deployed this one just on the "host" machine. I did not use any DBs in this case.

- deploy the project with using of embedded, by Maven plugin jetty-console, applet container

    ```sh
    ~ java -jar lavagna-jetty-console.war
    ```

- check **Lavagna** service on http://localhost:8080/ - login/pass is *user*, as a result you have to see UI like this one on screenshot

    ![image](img/2.png?raw=true "Lavagna on 'local' machine")