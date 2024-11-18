#!/bin/bash

PROJECT_ID=$(gcloud config get project)
REGION="europe-west9" 
REPOSITORY="toki-repo"
IMAGE_NAME="toki-api"
SERVICE_NAME="toki-api"
GIT_SHA=$(git rev-parse --short HEAD)

IMAGE_PATH="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/${IMAGE_NAME}:${GIT_SHA}"

gcloud run deploy ${SERVICE_NAME} \
  --image=${IMAGE_PATH} \
  --platform=managed \
  --region=${REGION} \
  --project=${PROJECT_ID} \
  --allow-unauthenticated \
  --port=3000 \
  --memory=512Mi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=2 \
  --labels="git-sha=${GIT_SHA},app=${SERVICE_NAME}" \
  --service-account="${SERVICE_NAME}-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --set-env-vars="GLEAM_ENV=prod,\
                  API_NAME=${SERVICE_NAME},\
                  API_PORT=3000,\
                  API_HOST=0.0.0.0,\
                  DB_PORT=5432,\
                  DB_HOST=ep-delicate-thunder-a20chm9w.eu-central-1.aws.neon.tech,\
                  DB_NAME=toki-prod,\
                  DB_USER=toki-prod,\
                  JWT_EXPIRES_IN=900,\
                  REFRESH_TOKEN_EXPIRES_IN=2592000" \
  --set-secrets="DB_PASSWORD=DB_PASSWORD:latest,\
                 JWT_SECRET_KEY=JWT_SECRET_KEY:latest,\
                 REFRESH_TOKEN_PEPPER=REFRESH_TOKEN_PEPPER:latest"

# Verify deployment
echo "Verifying deployment..."
gcloud run services describe ${SERVICE_NAME} \
  --platform=managed \
  --region=${REGION} \
  --format='get(status.url)'