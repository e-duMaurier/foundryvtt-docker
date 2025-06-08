FROM node:22-alpine

# Install unzip (making sure we have access to unzip and md5sum commands)
RUN apk add --no-cache unzip coreutils

# Create the mount point directories
RUN mkdir -p /opt/foundryvtt/resources/app && \
    mkdir -p /data/foundryvtt && \
    mkdir /host_files # zip file from the host will be mounted here

# Copy the run-server.sh into the image
COPY run-server.sh /usr/local/bin/run-server.sh
RUN chmod +x /usr/local/bin/run-server.sh

EXPOSE 30000

ENTRYPOINT ["/usr/local/bin/run-server.sh"]
