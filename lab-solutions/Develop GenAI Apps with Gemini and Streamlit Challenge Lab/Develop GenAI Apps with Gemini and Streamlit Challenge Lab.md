# [Develop GenAI Apps with Gemini and Streamlit: Challenge Lab](https://www.cloudskillsboost.google/course_templates/978/labs/488168)

## ⚠️ **Disclaimer:**
Script dan panduan ini disediakan untuk tujuan edukasi agar Anda dapat memahami proses lab dengan lebih baik. Sebelum menggunakannya, disarankan untuk meninjau setiap langkah guna memperoleh pemahaman yang lebih mendalam. Pastikan untuk mematuhi ketentuan layanan Qwiklabs, karena tujuan utamanya adalah mendukung pengalaman belajar Anda.


* Search **Workbench**(Vertex AI)
* Klik **OPEN JUPYTERLAB**
* Hapus file prompt-v1.0.0.ipynb
* Download file [ini](https://github.com/andregregs/juaragcp-s11/blob/main/lab-solutions/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit%20Challenge%20Lab/prompt-v1.0.0.ipynb)
* Upload file yg di download ke Jupyter
* Ubah PROJECT_ID kemudian Run Jupyter

### Run the following Commands in CloudShell

**Assign Variable**
```
export REGION=
```

```
gcloud auth list

gcloud services enable run.googleapis.com

git clone https://github.com/GoogleCloudPlatform/generative-ai.git

cd generative-ai/gemini/sample-apps/gemini-streamlit-cloudrun

gsutil cp gs://spls/gsp517/chef.py .

rm -rf Dockerfile chef.py

wget https://raw.githubusercontent.com/andregregs/juaragcp-s11/main/lab-solutions/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit%20Challenge%20Lab/Dockerfile.txt

wget https://raw.githubusercontent.com/andregregs/juaragcp-s11/main/lab-solutions/Develop%20GenAI%20Apps%20with%20Gemini%20and%20Streamlit%20Challenge%20Lab/chef.py

mv Dockerfile.txt Dockerfile

gcloud storage cp chef.py gs://$DEVSHELL_PROJECT_ID-generative-ai/

export PROJECT="$DEVSHELL_PROJECT_ID"


python3 -m venv gemini-streamlit
source gemini-streamlit/bin/activate
python3 -m  pip install -r requirements.txt
pip install streamlit google-cloud-aiplatform google-cloud-logging


streamlit run chef.py \
  --browser.serverAddress=localhost \
  --server.enableCORS=false \
  --server.enableXsrfProtection=false \
  --server.port 8080
```

* Klik link Streamlit di Terminal
* Coba run streamlit
* Ctrl+C di terminal kemudian run code selanjutnya

```
AR_REPO='chef-repo'
SERVICE_NAME='chef-streamlit-app' 
gcloud artifacts repositories create "$AR_REPO" --location="$REGION" --repository-format=Docker
gcloud builds submit --tag "$REGION-docker.pkg.dev/$PROJECT/$AR_REPO/$SERVICE_NAME"
python3 -m venv gemini-streamlit
source gemini-streamlit/bin/activate
python3 -m  pip install -r requirements.txt
pip install streamlit google-cloud-aiplatform google-cloud-logging

gcloud run deploy "$SERVICE_NAME" \
  --port=8080 \
  --image="$REGION-docker.pkg.dev/$PROJECT/$AR_REPO/$SERVICE_NAME" \
  --allow-unauthenticated \
  --region=$REGION \
  --platform=managed  \
  --project=$PROJECT \
  --set-env-vars=GCP_PROJECT=$PROJECT,GCP_REGION=$REGION
```

