#!/bin/bash

#
# This script will use aliyun container image syncer to sync blocked
# image from outside to inside
#

CURRENT_PATH=$(cd $(dirname $0); pwd)

if [ ! -n "$1" ] || [ ! -n "$2" ] || [ ! -n "$3" ] || [ ! -n "$4" ]; then
  echo "Usage: sync.sh <registry> <registry username> <registry password> <repo>"
fi

REGISTRY=$1
REGISTRY_USERNAME=$2
REGISTRY_PASSWORD=$3
REPO=$4

echo "====================================================="
echo "Sync target repo is $REGISTRY/$REPO, auth username is $REGISTRY_USERNAME"
echo "Waiting 5 seconds before start, if you want to change your username please use CTRL + C to stop script running."
echo "====================================================="

#sleep 5

#  - sed -i "s#USERNAME#${DOCKERHUB_USERNAME}#g" config.yaml
#  - sed -i "s#PASSWORD#${DOCKERHUB_PASSWORD}#g" config.yaml

IMAGE_SYNCER_VERSION="v1.3.0"
IMAGE_SYNCER_TAR_GZ="$CURRENT_PATH/image-syncer-${IMAGE_SYNCER_VERSION}-linux-amd64.tar.gz"
IMAGE_SYNCER_DOWNLOAD_URL="https://github.com/AliyunContainerService/image-syncer/releases/download/${IMAGE_SYNCER_VERSION}/${IMAGE_SYNCER_TAR_GZ}"
IMAGE_SYNCER="$CURRENT_PATH/image-syncer"
IMAGE_SYNCER_AUTH="$CURRENT_PATH/auth.yaml"
IMAGE_SYNCER_LIST="$CURRENT_PATH/images.yaml"

# Use this conf to generate image syncer json
SYNC_IMAGE_CONF="$CURRENT_PATH/sync_images.conf"

if [[ ! -e $IMAGE_SYNCER ]]; then
  echo "Downloading image syncer from $IMAGE_SYNCER_DOWNLOAD_URL..."
  wget https://github.com/AliyunContainerService/image-syncer/releases/download/${IMAGE_SYNCER_VERSION}/image-syncer-${IMAGE_SYNCER_VERSION}-linux-amd64.tar.gz
  tar -zxf image-syncer-${IMAGE_SYNCER_VERSION}-linux-amd64.tar.gz
fi

echo "Writing auth info into ${IMAGE_SYNCER_AUTH}..."
tee $IMAGE_SYNCER_AUTH <<EOF
$REGISTRY:
  username: $REGISTRY_USERNAME
  password: $REGISTRY_PASSWORD
EOF
echo "Write ${IMAGE_SYNCER_AUTH} succesfully."

echo "Generating sync images file $IMAGE_SYNCER_LIST for image syncer..."
rm -rf $IMAGE_SYNCER_LIST
for image in $(cat $SYNC_IMAGE_CONF);
do
  repo_name=$(basename $image)
  echo "${image}: ${REGISTRY}/${REPO}/${repo_name}" >> $IMAGE_SYNCER_LIST
done


echo "Syncing docker images..."
./image-syncer --proc=20 --auth=$IMAGE_SYNCER_AUTH --images=$IMAGE_SYNCER_LIST --retries=3
