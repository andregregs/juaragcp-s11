# Set text styles to print colored and bold text in the terminal
YELLOW=$(tput setaf 3)  # Set text color to yellow
BOLD=$(tput bold)        # Set text to bold
RESET=$(tput sgr0)       # Reset text to default format

echo "Please set the below values correctly"
# Prompt the user for REGION and PROCESSOR name input
with colored formatting
read -p "${YELLOW}${BOLD}Enter REGION: ${RESET}" REGION
read -p "${YELLOW}${BOLD}Enter Processor Name in TASK 2: ${RESET}" PROCESSOR

# Store REGION and PROCESSOR values as environment variables
export REGION PROCESSOR

# Display the list of authenticated Google Cloud accounts
gcloud auth list

# Retrieve the active PROJECT_ID and store it as an environment variable
export PROJECT_ID=$(gcloud config get-value core/project)

# Enable the Document AI service in the Google Cloud project
gcloud services enable documentai.googleapis.com --project $DEVSHELL_PROJECT_ID

# Wait for 10 seconds to ensure the service is activated before executing the next commands
sleep 10

# Create a local directory to store training data
mkdir ./document-ai-challenge

# Download required files from the Google Cloud bucket into the newly created directory
gsutil -m cp -r gs://spls/gsp367/* ~/document-ai-challenge/

# Retrieve an access token for authentication with Google Cloud services
ACCESS_CP=$(gcloud auth application-default print-access-token)

# Create a new processor for Document AI using an API request
curl -X POST \
  -H "Authorization: Bearer $ACCESS_CP" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "'"$PROCESSOR"'",
    "type": "FORM_PARSER_PROCESSOR"
  }' \
  "https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors"

# Create three Google Cloud Storage buckets for different purposes
gsutil mb -c standard -l $REGION -b on gs://$PROJECT_ID-input-invoices  # Bucket for input invoices
gsutil mb -c standard -l $REGION -b on gs://$PROJECT_ID-output-invoices  # Bucket for processed output
gsutil mb -c standard -l $REGION -b on gs://$PROJECT_ID-archived-invoices  # Bucket for archived invoices


# Create a BigQuery dataset named 'invoice_parser_results' in the US location
bq --location=US mk -d \
 --description "Form Parser Results" \
 ${PROJECT_ID}:invoice_parser_results

# Navigate to the directory containing the BigQuery table schema
cd ~/document-ai-challenge/scripts/table-schema

# Create a BigQuery table named 'doc_ai_extracted_entities' using a JSON schema file
bq mk --table \
invoice_parser_results.doc_ai_extracted_entities \
doc_ai_extracted_entities.json

# Navigate to the scripts directory
cd ~/document-ai-challenge/scripts

# Retrieve the active project ID and project number
PROJECT_ID=$(gcloud config get-value project)
PROJECT_NUMBER=$(gcloud projects list --filter="project_id:$PROJECT_ID" --format='value(project_number)')

# Get the Google Cloud Storage service account for the project
SERVICE_ACCOUNT=$(gcloud storage service-agent --project=$PROJECT_ID)

# Grant the Pub/Sub publisher role to the storage service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT \
  --role roles/pubsub.publisher

# Set the Cloud Function deployment location
export CLOUD_FUNCTION_LOCATION=$REGION

echo $CLOUD_FUNCTION_LOCATION

# Wait 30 seconds before proceeding
sleep 30

#!/bin/bash

# Function to deploy a Cloud Function
deploy_function() {
  gcloud functions deploy process-invoices \
  --gen2 \
  --region=${CLOUD_FUNCTION_LOCATION} \
  --entry-point=process_invoice \
  --runtime=python39 \
  --service-account=${PROJECT_ID}@appspot.gserviceaccount.com \
  --source=cloud-functions/process-invoices \
  --timeout=400 \
  --env-vars-file=cloud-functions/process-invoices/.env.yaml \
  --trigger-resource=gs://${PROJECT_ID}-input-invoices \
  --trigger-event=google.storage.object.finalize\
  --service-account $PROJECT_NUMBER-compute@developer.gserviceaccount.com \
  --allow-unauthenticated
}

# Attempt to deploy the Cloud Function until successful
deploy_success=false

while [ "$deploy_success" = false ]; do
  if deploy_function; then
    echo "Successfully deployed Cloud Run Function"
    deploy_success=true
  else
    echo "Failed to deploy Cloud Run Function, retrying in 10 seconds"
    sleep 10
  fi
  done

# Retrieve the Document AI processor ID
PROCESSOR_ID=$(curl -X GET \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
  -H "Content-Type: application/json" \
  "https://documentai.googleapis.com/v1/projects/$PROJECT_ID/locations/us/processors" | \
  grep '"name":' | \
  sed -E 's/.*"name": "projects\/[0-9]+\/locations\/us\/processors\/([^"]+)".*/\1/')


# Set environment variables for processor and region
export PROCESSOR_ID
export CLOUD_FUNCTION_LOCATION=$REGION
export PROJECT_ID=$(gcloud config get-value core/project)

# Deploy a Cloud Function triggered by new files in a Cloud Storage bucket
gcloud functions deploy process-invoices \
  --gen2 \
  --region=${CLOUD_FUNCTION_LOCATION} \
  --entry-point=process_invoice \
  --runtime=python39 \
  --service-account=${PROJECT_ID}@appspot.gserviceaccount.com \
  --source=cloud-functions/process-invoices \
  --timeout=400 \
  --trigger-resource=gs://${PROJECT_ID}-input-invoices \
  --trigger-event=google.storage.object.finalize \
  --update-env-vars=PROCESSOR_ID=${PROCESSOR_ID},PARSER_LOCATION=us,PROJECT_ID=${PROJECT_ID} \
  --service-account=$PROJECT_NUMBER-compute@developer.gserviceaccount.com

# Copy sample invoice data from Google Cloud Storage to the project's input bucket
gsutil -m cp -r gs://cloud-training/gsp367/* gs://${PROJECT_ID}-input-invoices/


