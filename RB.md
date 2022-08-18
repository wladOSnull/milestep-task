# Mile Step

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
- install **Maven** (bacause of *Lavagna* project)
