FROM jetty:9.4.48-jdk11-alpine
LABEL maintainer="https://github.com/wladOSnull"

COPY ./lavagna.war /var/lib/jetty/webapps/ROOT.war

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["java","-jar","/usr/local/jetty/start.jar"]