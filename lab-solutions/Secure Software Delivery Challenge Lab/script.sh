#!/bin/bash

# Mengatur environment variables
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
--format='value(projectNumber)')
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)

# Mengaktifkan layanan Google Cloud yang dibutuhkan
gcloud services enable \
cloudkms.googleapis.com \
run.googleapis.com \
cloudbuild.googleapis.com \
container.googleapis.com \
containerregistry.googleapis.com \
artifactregistry.googleapis.com \
containerscanning.googleapis.com \
ondemandscanning.googleapis.com \
binaryauthorization.googleapis.com

# Membuat direktori sample-app dan menyalin file contoh
mkdir sample-app && cd sample-app
gcloud storage cp gs://spls/gsp521/* .

# Membuat Artifact Registry untuk scanning dan produksi
gcloud artifacts repositories create artifact-scanning-repo \
--repository-format=docker \
--location=$REGION \
--description="Scanning repository"

gcloud artifacts repositories create artifact-prod-repo \
--repository-format=docker \
--location=$REGION \
--description="Production repository"

# Mengautentikasi Docker ke Artifact Registry
gcloud auth configure-docker $REGION-docker.pkg.dev

# Menambahkan IAM policy untuk Cloud Build

gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role="roles/ondemandscanning.admin"

# Membuat file konfigurasi Cloud Build
cat > cloudbuild.yaml <<EOF
steps:

- id: "build"
  name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image', '.']
  waitFor: ['-']

- id: "push"
  name: 'gcr.io/cloud-builders/docker'
  args: ['push',  '${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image']

images:
  - ${REGION}-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image
EOF

# Menjalankan Cloud Build
gcloud builds submit

# Membuat dan mengunggah catatan keamanan container
cat > ./vulnerability_note.json << EOM
{
"attestation": {
"hint": {
 "human_readable_name": "Container Vulnerabilities attestation authority"
}
}
}
EOM

NOTE_ID=vulnerability_note
curl -vvv -X POST \
-H "Content-Type: application/json"  \
-H "Authorization: Bearer $(gcloud auth print-access-token)"  \
--data-binary @./vulnerability_note.json  \
"https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/?noteId=${NOTE_ID}"

# Mengecek apakah catatan berhasil dibuat
curl -vvv -H "Authorization: Bearer $(gcloud auth print-access-token)" \
"https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}"

# Membuat Attestor untuk Binary Authorization
ATTESTOR_ID=vulnerability-attestor
gcloud container binauthz attestors create $ATTESTOR_ID \
--attestation-authority-note=$NOTE_ID \
--attestation-authority-note-project=${PROJECT_ID}

# Mengatur IAM policy untuk Binary Authorization
PROJECT_NUMBER=$(gcloud projects describe "${PROJECT_ID}"  --format="value(projectNumber)")
BINAUTHZ_SA_EMAIL="service-${PROJECT_NUMBER}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"

cat > ./iam_request.json << EOM
{
'policy': {
'bindings': [
 {
   'role': 'roles/containeranalysis.notes.occurrences.viewer',
   'members': [
     'serviceAccount:${BINAUTHZ_SA_EMAIL}'
   ]
 }
]
}
}
EOM

curl -X POST  \
-H "Content-Type: application/json" \
-H "Authorization: Bearer $(gcloud auth print-access-token)" \
--data-binary @./iam_request.json \
"https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}:setIamPolicy"

# Membuat KMS Key untuk Binary Authorization
KEY_LOCATION=global
KEYRING=binauthz-keys
KEY_NAME=lab-key
KEY_VERSION=1

gcloud kms keyrings create "${KEYRING}" --location="${KEY_LOCATION}"

gcloud kms keys create "${KEY_NAME}" \
--keyring="${KEYRING}" --location="${KEY_LOCATION}" \
--purpose asymmetric-signing   \
--default-algorithm="ec-sign-p256-sha256"

# Menambahkan kunci publik ke Attestor
gcloud beta container binauthz attestors public-keys add  \
--attestor="${ATTESTOR_ID}"  \
--keyversion-project="${PROJECT_ID}"  \
--keyversion-location="${KEY_LOCATION}" \
--keyversion-keyring="${KEYRING}" \
--keyversion-key="${KEY_NAME}" \
--keyversion="${KEY_VERSION}"

# Mengekspor dan mengimpor kebijakan Binary Authorization
gcloud container binauthz policy export > my_policy.yaml
gcloud container binauthz policy import my_policy.yaml

# Menambahkan IAM policy untuk Cloud Build

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
--role roles/binaryauthorization.attestorsViewer

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
--member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
--role roles/cloudkms.signerVerifier

# Meng-clone repo dan membangun attestation tool
git clone https://github.com/GoogleCloudPlatform/cloud-builders-community.git
cd cloud-builders-community/binauthz-attestation
gcloud builds submit . --config cloudbuild.yaml
cd ../..
rm -rf cloud-builders-community

# Menjalankan kembali Cloud Build
gcloud builds submit

# Menambahkan IAM policy untuk Cloud Run agar publik dapat mengaksesnya
gcloud beta run services add-iam-policy-binding --region=$REGION --member=allUsers --role=roles/run.invoker auth-service
