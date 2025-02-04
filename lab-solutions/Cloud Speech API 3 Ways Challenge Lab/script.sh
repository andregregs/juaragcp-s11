#!/bin/bash

# Menampilkan pesan bahwa eksekusi dimulai
echo "Starting Execution"

# Mendefinisikan URI file audio untuk digunakan dalam proses sintesis dan pengenalan suara
audio_uri="gs://cloud-samples-data/speech/corbeau_renard.flac"

# Mendapatkan ID proyek dari konfigurasi gcloud
export PROJECT_ID=$(gcloud config get-value project)

# Mengaktifkan virtual environment
source venv/bin/activate

# Membuat file JSON untuk permintaan API Text-to-Speech
cat > synthesize-text.json <<EOF
{
  'input':{
     'text':'Cloud Text-to-Speech API allows developers to include
        natural-sounding, synthetic human speech as playable audio in
        their applications. The Text-to-Speech API converts text or
        Speech Synthesis Markup Language (SSML) input into audio data
        like MP3 or LINEAR16 (the encoding used in WAV files).'
  },
  'voice':{
     'languageCode':'en-gb',
     'name':'en-GB-Standard-A',
     'ssmlGender':'FEMALE'
  },
  'audioConfig':{
     'audioEncoding':'MP3'
  }
}
EOF

# Mengirim permintaan ke API Text-to-Speech untuk menghasilkan audio
curl -H "Authorization: Bearer "$(gcloud auth application-default print-access-token) \
-H "Content-Type: application/json; charset=utf-8" \
-d @synthesize-text.json "https://texttospeech.googleapis.com/v1/text:synthesize" \
> $task_2_file_name

# Membuat file JSON untuk permintaan API Speech-to-Text
cat > "$task_3_request_file" <<EOF
{
  "config": {
    "encoding": "FLAC",
    "sampleRateHertz": 44100,
    "languageCode": "fr-FR"
  },
  "audio": {
    "uri": "$audio_uri"
  }
}
EOF

# Mengirim permintaan ke API Speech-to-Text untuk mengenali teks dari file audio
curl -s -X POST -H "Content-Type: application/json" \
--data-binary @"$task_3_request_file" \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" \
-o "$task_3_response_file"

# Mengirim permintaan ke API Google Translate untuk menerjemahkan teks dari bahasa Jepang ke Inggris
response=$(curl -s -X POST \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json; charset=utf-8" \
-d "{\"q\": \"$task_4_sentence\"}" \
"https://translation.googleapis.com/language/translate/v2?key=${API_KEY}&source=ja&target=en")

# Menyimpan respons terjemahan ke dalam file
echo "$response" > "$task_4_file"

# Mengirim permintaan ke API Google Translate untuk mendeteksi bahasa dari kalimat
curl -s -X POST \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json; charset=utf-8" \
-d "{\"q\": [\"$task_5_sentence\"]}" \
"https://translation.googleapis.com/language/translate/v2/detect?key=${API_KEY}" \
-o "$task_5_file"