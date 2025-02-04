# [Cloud Speech API 3 Ways: Challenge Lab](https://www.cloudskillsboost.google/course_templates/700/labs/461583)

## ⚠️ **Disclaimer:**
Script dan panduan ini disediakan untuk tujuan edukasi agar Anda dapat memahami proses lab dengan lebih baik. Sebelum menggunakannya, disarankan untuk meninjau setiap langkah guna memperoleh pemahaman yang lebih mendalam. Pastikan untuk mematuhi ketentuan layanan Qwiklabs, karena tujuan utamanya adalah mendukung pengalaman belajar Anda.

## 🚀 **Steps to Execute in Cloud Shell:**
### Run the following Commands in CloudShell

```
export ZONE=$(gcloud compute instances list lab-vm --format 'csv[no-heading](zone)')
gcloud compute ssh lab-vm --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet
```

* Pada bagian Search, ketik `Credentials`
* Tekan `CREATE CREDENTIALS` lalu pilih API key.

```
export API_KEY=
export task_2_file_name=""
export task_3_request_file=""
export task_3_response_file=""
export task_4_sentence=""
export task_4_file=""
export task_5_sentence=""
export task_5_file=""
```

```
curl -LO raw.githubusercontent.com/andregregs/juaragcp-s11/refs/heads/main/lab-solutions/Cloud%20Speech%20API%203%20Ways%20Challenge%20Lab/script.sh

sudo chmod +x script.sh

./script.sh
```