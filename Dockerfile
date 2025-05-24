FROM node:22-alpine

# Remove default user, create directories, and install needed packages.
RUN deluser node && \
    mkdir -p /opt/foundryvtt/resources/app && \
    mkdir -p /data/foundryvtt && \
    apk add --update --no-cache su-exec unzip

# Copy the startup script.
COPY run-server.sh /opt/foundryvtt/run-server.sh
RUN chmod +x /opt/foundryvtt/run-server.sh

# Copy the entrypoint script and mark it executable.
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /opt/foundryvtt

VOLUME /data/foundryvtt
VOLUME /host
VOLUME /opt/foundryvtt/resources/app

EXPOSE 30000

ENTRYPOINT ["/entrypoint.sh"]
CMD ["resources/app/main.mjs", "--headless", "--dataPath=/data/foundryvtt"]
