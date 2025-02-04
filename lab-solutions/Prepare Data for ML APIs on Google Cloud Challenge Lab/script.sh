#!/bin/bash

# Function to get input from the user
get_input() {
    local prompt="$1"
    local var_name="$2"
    
    read input
    export "$var_name"="$input"
}

# Mengumpulkan input dari pengguna untuk variabel yang dibutuhkan
get_input "BigQuery Dataset Name:" "DATASET"
get_input "Cloud Storage Bucket Name:" "BUCKET"
get_input "Enter the table called:" "TABLE"
get_input "Enter the BUCKET_URL_1 value Task 3:" "BUCKET_URL_1"
get_input "Enter the BUCKET_URL_2 Task 4:" "BUCKET_URL_2"

# Mengaktifkan layanan API Keys di Google Cloud
gcloud services enable apikeys.googleapis.com

# Membuat API Key dengan nama tampilan "awesome"
gcloud alpha services api-keys create --display-name="awesome"

# Mengambil nama API Key yang baru dibuat
KEY_NAME=$(gcloud alpha services api-keys list --format="value(name)" --filter "displayName=awesome")

# Mendapatkan string API Key
API_KEY=$(gcloud alpha services api-keys get-key-string $KEY_NAME --format="value(keyString)")

# Mengambil region default Google Cloud
export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Mengambil project ID
PROJECT_ID=$(gcloud config get-value project)

# Mengambil project number
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="json" | jq -r '.projectNumber')

# Membuat dataset BigQuery
bq mk $DATASET

# Membuat bucket Cloud Storage
gsutil mb gs://$BUCKET

# Menyalin file lab dari Google Cloud Storage ke lokal
gsutil cp gs://cloud-training/gsp323/lab.csv  .
gsutil cp gs://cloud-training/gsp323/lab.schema .

# Membuat tabel BigQuery dengan skema yang diunduh
bq mk --table $DATASET.$TABLE lab.schema

# Memberikan peran IAM ke service account default
gcloud projects add-iam-policy-binding $PROJECT_ID --member "serviceAccount:$PROJECT_NUMBER-compute@developer.gserviceaccount.com" --role "roles/storage.admin"

# Memperbarui subnet VPC untuk mengaktifkan akses IP pribadi ke Google
gcloud compute networks subnets update default --region $REGION --enable-private-ip-google-access

# Membuat service account baru
gcloud iam service-accounts create awesome --display-name "my natural language service account"
sleep 15

# Menghasilkan kunci untuk service account
gcloud iam service-accounts keys create ~/key.json --iam-account awesome@${PROJECT_ID}.iam.gserviceaccount.com

# Mengaktifkan service account
export GOOGLE_APPLICATION_CREDENTIALS="/home/$USER/key.json"
sleep 30
gcloud auth activate-service-account awesome@${PROJECT_ID}.iam.gserviceaccount.com --key-file=$GOOGLE_APPLICATION_CREDENTIALS

# Melakukan autentikasi ke Google Cloud
gcloud auth login --no-launch-browser --quiet

# Membuat cluster Dataproc
gcloud dataproc clusters create awesome --enable-component-gateway --region $REGION --master-machine-type e2-standard-2 --master-boot-disk-type pd-balanced --master-boot-disk-size 100 --num-workers 2 --worker-machine-type e2-standard-2 --worker-boot-disk-type pd-balanced --worker-boot-disk-size 100 --image-version 2.2-debian12 --project $PROJECT_ID

# Mengambil nama instance VM pertama di dalam project
VM_NAME=$(gcloud compute instances list --project="$PROJECT_ID" --format=json | jq -r '.[0].name')

# Mengambil zona VM
export ZONE=$(gcloud compute instances list $VM_NAME --format 'csv[no-heading](zone)')

# Menyalin file data dari bucket ke storage lokal VM
gcloud compute ssh --zone "$ZONE" "$VM_NAME" --project "$PROJECT_ID" --quiet --command="gsutil cp gs://cloud-training/gsp323/data.txt /data.txt"

# Menjalankan job Spark di cluster Dataproc
gcloud dataproc jobs submit spark --cluster=awesome --region=$REGION --class=org.apache.spark.examples.SparkPageRank --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar --project=$PROJECT_ID -- /data.txt

# Membersihkan file yang tidak diperlukan
remove_files() {
    for file in *; do
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            if [[ -f "$file" ]]; then
                rm "$file"
            fi
        fi
    done
}

remove_files
