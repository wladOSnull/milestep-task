FROM jetty:9.4.48-jdk11-alpine
MAINTAINER wladosnull

COPY ./lavagna.war /var/lib/jetty/webapps/ROOT.war

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["java","-jar","/usr/local/jetty/start.jar"]