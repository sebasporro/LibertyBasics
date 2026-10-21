FROM icr.io/appcafe/open-liberty:kernel-slim-java17-openj9-ubi

COPY --chown=1001:0 server.xml /config/server.xml
RUN features.sh
COPY --chown=1001:0 server-info.war /config/dropins/server-info.war
RUN configure.sh