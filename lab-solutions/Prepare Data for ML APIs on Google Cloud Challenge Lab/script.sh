#!/bin/bash

# Function to get input from the user
get_input() {
    local prompt="$1"
    local var_name="$2"
    read -p "$prompt " input
    export "$var_name"="$input"
}

# Gather inputs for the required variables
get_input "Enter the BigQuery Dataset Name:" "DATASET"
get_input "Enter the Cloud Storage Bucket Name:" "BUCKET"
get_input "Enter the table called Task 1:" "TABLE"
get_input "Enter the BUCKET_URL_1 Task 3:" "BUCKET_URL_1"
get_input "Enter the BUCKET_URL_2 Task 4:" "BUCKET_URL_2"

# Enable API keys service
gcloud services enable apikeys.googleapis.com

# Create an API key
gcloud alpha services api-keys create --display-name="awesome"

# Retrieve API key name
KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=awesome")

# Get API key string
API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")

# Get default Google Cloud region
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Retrieve project ID
PROJECT_ID=$(gcloud config get-value project)

# Retrieve project number
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="json" | jq -r '.projectNumber')

# Create BigQuery dataset
bq mk $DATASET

# Create Cloud Storage bucket
gsutil mb gs://$BUCKET

# Copy lab files from GCS
gsutil cp gs://cloud-training/gsp323/lab.csv  .
gsutil cp gs://cloud-training/gsp323/lab.schema .


# Display schema contents
echo "Displaying schema contents"
cat lab.schema

echo '[
    {"type":"STRING","name":"guid"},
    {"type":"BOOLEAN","name":"isActive"},
    {"type":"STRING","name":"firstname"},
    {"type":"STRING","name":"surname"},
    {"type":"STRING","name":"company"},
    {"type":"STRING","name":"email"},
    {"type":"STRING","name":"phone"},
    {"type":"STRING","name":"address"},
    {"type":"STRING","name":"about"},
    {"type":"TIMESTAMP","name":"registered"},
    {"type":"FLOAT","name":"latitude"},
    {"type":"FLOAT","name":"longitude"}
]' > lab.schema

# Create BigQuery table
bq mk --table $DATASET.$TABLE lab.schema

# Run Dataflow job to load data into BigQuery
gcloud dataflow jobs run awesome-jobs --gcs-location gs://dataflow-templates-$REGION/latest/GCS_Text_to_BigQuery --region $REGION --worker-machine-type e2-standard-2 --staging-location gs://$DEVSHELL_PROJECT_ID-marking/temp --parameters inputFilePattern=gs://cloud-training/gsp323/lab.csv,JSONPath=gs://cloud-training/gsp323/lab.schema,outputTable=$DEVSHELL_PROJECT_ID:$DATASET.$TABLE,bigQueryLoadingTemporaryDirectory=gs://$DEVSHELL_PROJECT_ID-marking/bigquery_temp,javascriptTextTransformGcsPath=gs://cloud-training/gsp323/lab.js,javascriptTextTransformFunctionName=transform

# Grant IAM roles to service account
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member "serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
    --role "roles/storage.admin"

# Assign IAM roles to user
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=user:$USER_EMAIL \
  --role=roles/dataproc.editor

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=user:$USER_EMAIL \
  --role=roles/storage.objectViewer

# Update VPC subnet for private IP access
gcloud compute networks subnets update default \
    --region $REGION \
    --enable-private-ip-google-access

# Create a service account
gcloud iam service-accounts create awesome \
  --display-name "my natural language service account"

sleep 15

# Generate service account key
gcloud iam service-accounts keys create ~/key.json \
  --iam-account awesome@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com

sleep 15

# Activate service account
export GOOGLE_APPLICATION_CREDENTIALS="/home/$USER/key.json"

sleep 30

gcloud auth activate-service-account awesome@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com --key-file=$GOOGLE_APPLICATION_CREDENTIALS


# Run ML entity analysis
gcloud ml language analyze-entities --content="Old Norse texts portray Odin as one-eyed and long-bearded, frequently wielding a spear named Gungnir and wearing a cloak and a broad hat." > result.json

# Authenticate to Google Cloud without launching a browser
gcloud auth login --no-launch-browser --quiet

# Copy result to bucket
gsutil cp result.json $BUCKET_URL_2

cat > request.json <<EOF
{
  "config": {
      "encoding":"FLAC",
      "languageCode": "en-US"
  },
  "audio": {
      "uri":"gs://cloud-training/gsp323/task3.flac"
  }
}
EOF

# Perform speech recognition using Google Cloud Speech-to-Text API
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > result.json

# Copy the speech recognition result to a Cloud Storage bucket
gsutil cp result.json $BUCKET_URL_1

# Create a new service account named 'quickstart'
gcloud iam service-accounts create quickstart

sleep 15

# Create a service account key for 'quickstart'
gcloud iam service-accounts keys create key.json --iam-account quickstart@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com

sleep 15

# Step 27: Authenticate using the created service account key
echo "Activating service account"
gcloud auth activate-service-account --key-file key.json

# Step 28: Create a request JSON file for Video Intelligence API
echo "Creating request JSON file for Video Intelligence API"
cat > request.json <<EOF 
{
   "inputUri":"gs://spls/gsp154/video/train.mp4",
   "features": [
       "TEXT_DETECTION"
   ]
}
EOF

# Step 29: Annotate the video using Google Cloud Video Intelligence API
echo "Sending video annotation request"
curl -s -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    'https://videointelligence.googleapis.com/v1/videos:annotate' \
    -d @request.json

# Step 30: Retrieve the results of the video annotation
echo "Retrieving video annotation results"
curl -s -H 'Content-Type: application/json' -H "Authorization: Bearer $ACCESS_TOKEN" 'https://videointelligence.googleapis.com/v1/operations/OPERATION_FROM_PREVIOUS_REQUEST' > result1.json

sleep 30

# Step 31: Perform speech recognition again
echo "Performing speech recognition again"
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > result.json

# Step 32: Annotate the video again using Google Cloud Video Intelligence API
echo "Sending another video annotation request"
curl -s -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    'https://videointelligence.googleapis.com/v1/videos:annotate' \
    -d @request.json

# Step 33: Retrieve the new video annotation results
echo "Retrieving new video annotation results"
curl -s -H 'Content-Type: application/json' -H "Authorization: Bearer $ACCESS_TOKEN" 'https://videointelligence.googleapis.com/v1/operations/OPERATION_FROM_PREVIOUS_REQUEST' > result1.json

# Function to prompt user to check their progress
function check_progress {
    while true; do
        echo
        echo -n "Have you checked your progress for Task 3 & Task 4? (Y/N): "
        read -r user_input
        if [[ "$user_input" == "Y" || "$user_input" == "y" ]]; then
            echo
            echo "Great! Proceeding to the next steps"
            echo
            break
        elif [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
            echo
            echo "Please check your progress for Task 3 & Task 4 and then press Y to continue."
        else
            echo
            echo "Invalid input. Please enter Y or N."
        fi
    done
}

# Call function to check progress before proceeding
check_progress

# Step 34: Authenticate to Google Cloud without launching a browser
echo "Authenticating to Google Cloud"
echo
gcloud auth login --no-launch-browser --quiet

# Step 35: Create a new Dataproc cluster
echo "Creating Dataproc cluster"
gcloud dataproc clusters create awesome --enable-component-gateway --region $REGION --master-machine-type e2-standard-2 --master-boot-disk-type pd-balanced --master-boot-disk-size 100 --num-workers 2 --worker-machine-type e2-standard-2 --worker-boot-disk-type pd-balanced --worker-boot-disk-size 100 --image-version 2.2-debian12 --project $DEVSHELL_PROJECT_ID

# Step 36: Get the VM instance name from the project
echo "Fetching VM instance name"
VM_NAME=$(gcloud compute instances list --project="$DEVSHELL_PROJECT_ID" --format=json | jq -r '.[0].name')

# Step 37: Get the compute zone of the VM
echo "Fetching VM zone"
export ZONE=$(gcloud compute instances list $VM_NAME --format 'csv[no-heading](zone)')

# Step 48: Copy data from Cloud Storage to HDFS in the VM
echo "Copying data to HDFS on VM"
gcloud compute ssh --zone "$ZONE" "$VM_NAME" --project "$DEVSHELL_PROJECT_ID" --quiet --command="hdfs dfs -cp gs://cloud-training/gsp323/data.txt /data.txt"

# Step 39: Copy data from Cloud Storage to local storage in the VM
echo "Copying data to local storage on VM"
gcloud compute ssh --zone "$ZONE" "$VM_NAME" --project "$DEVSHELL_PROJECT_ID" --quiet --command="gsutil cp gs://cloud-training/gsp323/data.txt /data.txt"

# Step 40: Submit a Spark job to the Dataproc cluster
echo "Submitting Spark job to Dataproc"
gcloud dataproc jobs submit spark \
  --cluster=awesome \
  --region=$REGION \
  --class=org.apache.spark.examples.SparkPageRank \
  --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
  --project=$DEVSHELL_PROJECT_ID \
  -- /data.txt

echo -e "\n"  # Adding one blank line

cd

remove_files() {
    # Loop through all files in the current directory
    for file in *; do
        # Check if the file name starts with "gsp", "arc", or "shell"
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            # Check if it's a regular file (not a directory)
            if [[ -f "$file" ]]; then
                # Remove the file and echo the file name
                rm "$file"
                echo "File removed: $file"
            fi
        fi
    done
}

remove_files