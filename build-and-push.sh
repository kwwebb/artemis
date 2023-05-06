#!/bin/bash

if [ -z $2 ]; then
       echo "Usage: $0 <repository> <version>"
       echo " "
       echo "Example: $0 kwwebb/artemis 2.9.0"
       exit 0
fi

version=$2
repository=$1:$2
echo "Building Artemis version: $version"
echo "Pushing to repository: $repository"

source prepare-docker.sh --from-release --artemis-version $version
docker buildx build --platform linux/arm64,linux/amd64 --push -t $repository .
rm -rf _TMP_
