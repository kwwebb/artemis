# Docker Artemis

Written by: Kingsley Webb, based on official Apache Artemis docker layout.

Github: <a name="https://github.com/kwwebb/artemis">https://github.com/kwwebb/artemis</a>

## Contents
1. Running
    1. [docker](#docker)
    1. [docker-compose.yml](#docker-compose)
1. [Build and Push to repository](#build-and-push)
1. [Environment Variables](#env)
1. [Mapping point](#mapping)
1. [Lifecycle of the execution](#lifecycle)
1. Manual
    1. [Manual Prepare](#preparing)
    1. [Manual Building](#building)
    1. [Manual Manifest Push](#manifest)


This source repository has everything you need to build the latest version of Apache Artemis into docker image.  This has been designed to run on Ubuntu with Temurin Java.

When a container is run a broker will be created an initialised once.  The broker will be configured based on a hardware test of the environment it is run on.

**TLDR;**

To run a container from this repository use the [docker-compose.yml](#docker-compose).

To build a new version for your own use or customisation simply use the `build-and-push.sh` script to build and publish an image and then use the `docker-compose.yml` below to execute it.

**Note:** Production envrionments would need to externalise the Artemis config and data to allow for upgrading and outliving the destruction of a container.  Otherwise, just use ephemeral storage for dev and testing.

## Running

### docker <a name="docker"></a>

Stateless run:
```
$ docker run --rm -it -p 61616:61616 -p 8161:8161 <repository>/artemis 
```

Stateful run:
```
docker run -it -p 61616:61616 -p 8161:8161 -v <local-volume>:/var/lib/artemis-instance <repository>/artemis 
```
where `<local-volume>` is a folder where the broker instance will be initialised, populated and will remain when the container is destroyed or upgraded.

### docker-compose.yml <a name="docker-compose"></a>

```
version: '2.4'

services:
  artemis:
    container_name: artemis 
    image: kwwebb/artemis:2.28.0 
    restart: unless-stopped
    volumes:
      - ./etc:/var/lib/artemis-instance
    ports:
      - 61616:61616
      - 8161:8161
```

To limit resource usage and bind on the loopback interface only (for security):
```
version: '2.4'

services:
  artemis:
    container_name: artemis 
    image: kwwebb/artemis:2.28.0 
    restart: unless-stopped
    volumes:
      - ./etc:/var/lib/artemis-instance
    ports:
      - 127.0.0.1:61616:61616
      - 127.0.0.1:8161:8161
    cpus: 0.5    
    mem_reservation: 128m
    mem_limit: 512m

```

## Build and Push to repository <a name="build-and-push"></a>

Command to build and push both `amd64` and `arm64` images:
```
$ ./build-and-push.sh <repository> <version>
```
See [Manual Preparing](#preparing)

Note: Your repository will need to support the latest manifest file format for this to work.  Docker Hub will support this but at this time AWS ECR does not.  See [Manual Manifest Push](#manual-manifest-push).


## Environment Variables <a name="env"></a>

Environment variables determine the options sent to `artemis create` on first execution of the Docker container. The available options are:

**`ARTEMIS_USER`**

The administrator username. The default is `artemis`.

**`ARTEMIS_PASSWORD`**

The administrator password. The default is `artemis`.

**`ANONYMOUS_LOGIN`**

Set to `true` to allow anonymous logins. The default is `false`.

**`EXTRA_ARGS`**

Additional arguments sent to the `artemis create` command. The default is `--http-host 0.0.0.0 --relax-jolokia`.
Setting this value will override the default. See the documentation on `artemis create` for available options.

**Final broker creation command:**

The combination of the above environment variables results in the `docker-run.sh` script calling
the following command to create the broker instance the first time the Docker container runs:

    ${ARTEMIS_HOME}/bin/artemis create --user ${ARTEMIS_USER} --password ${ARTEMIS_PASSWORD} --silent ${LOGIN_OPTION} ${EXTRA_ARGS}

Note: `LOGIN_OPTION` is either `--allow-anonymous` or `--require-login` depending on the value of `ANONYMOUS_LOGIN`.


## Mapping point <a name="mapping"></a>

- `/var/lib/artemis-instance`

It's possible to map a folder as the instance broker.
This will hold the configuration and the data of the running broker. This is useful for when you want the data persisted outside of a container.


## Lifecycle of the execution <a name="lifecycle"></a>

A broker instance will be created during the execution of the instance. If you pass a mapped folder for `/var/lib/artemis-instance` an image will be created or reused depending on the contents of the folder.

## Manual

### <a name="preparing"></a>Manual Prepare 

Use the script ./prepare-docker.sh as it will copy the docker files under the binary distribution.

Prepare - download and extract a version of Artemis `(_TMP_ directory)`, ready to build:
```
$ ./prepare-docker.sh --from-release --artemis-version 2.16.0
```

### Manual Building <a name="building"></a>

Login to your docker repository
```
docker login <repository>
```
repository - your private or public repository 

```
docker buildx build --platform linux/arm64,linux/amd64 --push -t <repository>:<version> .

repository - your private/public repository
version - the version of the build e.g. 1.5 or latest
```

### Manual Manifest Push <a name="manifest"></a>

1. Run the manual prepare (above) e.g. 2.28.0
1. Manually build as follows:

    Only build one architecture at a time and push to your local repository as follows (e.g. amd64 & arm64):
    ```
    docker buildx build --platform linux/amd64 --load -t artemis:amd64 .
    docker buildx build --platform linux/arm64 --push -t artemis:arm64 .

    ```
1. Create a manifest referencing the two images just created (above) e.g. using version 2.28.0:
    ```
    docker manifest create artemis:2.28.0 \
      artemis:amd64 \
      artemis:arm64
    ```
1. Login to your remote docker repository
1. Push the local image to your remote repository
    ```
    docker tag artemis:2.28.0 <my-repository>/artemis:2.28.0
    docker push <my-repository>/artemis:2.28.0
    ```