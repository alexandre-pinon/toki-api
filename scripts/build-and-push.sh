#!/bin/bash

PROJECT_ID=$(gcloud config get project)
REGION="europe-west9"
REPOSITORY="toki-repo"
IMAGE_NAME="toki-api"
GIT_SHA=$(git rev-parse --short HEAD)
IMAGE_PATH="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${IMAGE_NAME}:${GIT_SHA}"

gcloud auth configure-docker ${REGION}-docker.pkg.dev

docker build -t ${IMAGE_PATH} --platform linux/amd64 .

docker push ${IMAGE_PATH}

echo "Image built and pushed: ${IMAGE_PATH}"