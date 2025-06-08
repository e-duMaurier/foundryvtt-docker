# FoundryVTT - Docker Container

_A lightweight, multi-user compatible FoundryVTT container_

## Overview

This repository hosts a my FoundryVTT Dockerfile for [dumaurier/foundry-docker](https://hub.docker.com/repository/docker/dumaurier/foundry-docker/general) hosted on Docker Hub.
It is designed for improved flexibility, security, and multi-user support. Unlike standard implementations, this container **runs as a non-root user**, ensuring a safer execution environment, particularly on shared systems.

- **Updated Node.js Support** – Set**Node.js 22** for better compatibility and performance.
- **Non-Root Execution** – Runs without root privileges, improving security and usability in shared environments.
- **Multi-User & Multi-Instance Compatibility** – Allows different users to run separate instances or host different game systems (e.g., Pathfinder, D&D).
- **Flexible Directory & Volume Management** – Supports customised paths for user-specific data storage and game system separation.

---

## Prerequisites

- [FoundryVTT](https://foundryvtt.com/) - A Foundry VTT Licence.
- [Docker](https://docs.docker.com/engine/install/) - To run the Foundry VTT instance(s).
- [Docker Compose](https://docs.docker.com/compose/install/) - To make starting/stopping instances easier.

## Setup Instructions

Ensure that you have **Docker** and **Docker Compose** installed. Instructions for setting these up can be found through the links above

### Step 1 - Create your directory structure

In your user home directory, create a directory to hold your `docker-compose.yml` and `FoundryVTT.zip` files.

Inside this directory, create two more directories, one for the application data, and one for the user data.

```bash
mkdir -p ~/foundry/appdata
mkdir -p ~/foundry/userdata
```

** Example Directory Structures**
Single User/Multiple Instances

```tree
/home/
├── user/
│   ├── foundry/
│   │   ├── pf2e/
|	|	|	|── userdata/
|	|	|	|── appdata/
│   │   ├── dnd/
|	|	|	|── userdata/
|	|	|	|── appdata/
```

Multiple Users/Single Instances

```tree
/home/
├── user1/
│   ├── foundry/
|	|	|── userdata/
|	|	|── appdata/
├── user2/
│   ├── foundry/
|	|	|── userdata/
|	|	|── appdata/
```

Multiple Users/Single Instances

```tree
/home/
├── user1/
│   ├── foundry/
|	|	|── userdata/
|	|	|── appdata/
├── user2/
│   ├── foundry/
|	|	|── userdata/
|	|	|── appdata/
```

### Step 2 - Download the docker-compose.yml file

Once the file is downloaded, copy or move it to the required foundry directory.

```tree
/home/
├── user/
│   ├── foundry/
|	|	|── docker-compose.yml
|	|	|── userdata/
|	|	|── appdata/
```

### Step 3 - Edit the docker-compose.yml file

It is recommended to set both the `hostname`, and `container_name` the same, and matching the name set directly under services, especially if you will be running multiple instances, or single instances for multiple users.

#### Set the Service, Container_name, and Hostname

Change the following values, if needed, to change how the container will be named and set up.

```yaml
fvtt: # If using multiple instances, or users, change this for each instance/user (fvtt-user1, fvtt-user2, fvtt-dnd5e, fvtt-pf2e etc.).
  container_name: fvtt # Keeping this the same as the name above, will help keep it easy to identify.
  hostname: fvtt # Matching this with the container name above, can help if using proxies and portianer for managing urls.
```

**Example**

```yaml
fvtt:
  container_name: fvtt
  hostname: fvtt
```

```yaml
foundry-pf2e:
  container_name: foundry-pf2e
  hostname: foundry-pf2e
```

#### Set the Volume directories

Set the `foundry` , the `appdata` and the `userdata` directories under `volumes`, by editing the following lines.

```yaml
- /your/foundry/instance/system/userdata:/data/foundryvtt
- /your/foundry/instance/system/appdata:/opt/foundryvtt/resources/app
- /your/foundry/instance/system:/host_files
```

**Example**

```yaml
/home/user/foundry/userdata:/data/foundryvtt
/home/user/foundry/appdata:/opt/foundryvtt/resources/app
/home/user/foundry:/host_files
```

#### Set the Ports

Edit the following lines to change the port, but only the number on the left. The value on the right must remain as it is.

```yaml
ports:
  - "30000:30000"
```

If you will be running multiple instances, it is recommended to have them on separate ports, especially if these will be accessible on different domains, or will be running at the same time.

When changing the port, only alter the value on the left, and ensure this is not a port that is already in use on your server.
**Example**

```yaml
ports:
  - "300100:30000"
```

### Step 4 - Download Foundry VTT

Since FoundryVTT requires a purchased licence, it's files are **not** included in this image. You will need to manually download the `.zip` file from your FoundryVTT account.

- Go to the Purchased Licences section from your profile page on the Foundry VTT website.
- Select your required version from the 'Download Version' drop-down.
- Download the `Node.js` version from the 'Operating System' drop-down.
- Save, or copy, the zip file to the same directory as the `docker-compose.yaml` file from step 2.

```tree
/home/
├── user/
│   ├── foundry/
|	|	|── docker-compose.yml
|	|	|── FoundryVTT-13.344.zip
|	|	|── userdata/
|	|	|── appdata/
```

### Step 5 - Run the server

From the directory with the `docker-compose.yml` file, start the container.

```bash
docker compose up -d
```

This will run the container as a service, so that it will not end when the terminal is closed.
If you want to review the logs as the container is starting, you could also use

```bash
docker compose up -d && docker compose logs -f
```

Once the container is running, check you can access the Foundry VTT instance through your web browser, entering the URL, and Foundry port, of your server`http://<server-ip>:<port>`
For example `http://192.168.10.1:30000`
