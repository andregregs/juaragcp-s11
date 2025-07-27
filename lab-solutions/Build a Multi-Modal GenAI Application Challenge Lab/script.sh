#!/bin/bash

# 1. Mendapatkan Project ID
ID="$(gcloud projects list --format='value(PROJECT_ID)')"

# 2. Membuat file Python untuk generate gambar menggunakan Vertex AI
cat > GenerateImage.py <<EOF_CP
import argparse
import vertexai
from vertexai.preview.vision_models import ImageGenerationModel

def generate_image(
    project_id: str, location: str, output_file: str, prompt: str
):
    vertexai.init(project=project_id, location=location)
    model = ImageGenerationModel.from_pretrained("imagegeneration@002")
    images = model.generate_images(
        prompt=prompt,
        number_of_images=1,
        seed=1,
        add_watermark=False,
    )
    images[0].save(location=output_file)
    return images

generate_image(
    project_id='$ID',
    location='$REGION',
    output_file='image.jpeg',
    prompt='Create an image of a cricket ground in the heart of Los Angeles',
)
EOF_CP

# 3. Menunggu 20 detik
sleep 20

# 4. Menjalankan skrip GenerateImage.py dua kali
/usr/bin/python3 /home/student/GenerateImage.py
/usr/bin/python3 /home/student/GenerateImage.py

# 5. Menunggu 10 detik
sleep 10

# 6. Membuat file Python untuk generate teks menggunakan Vertex AI
cat > genai.py <<EOF_CP
import vertexai
from vertexai.generative_models import GenerativeModel, Part

def generate_text(project_id: str, location: str) -> str:
    vertexai.init(project=project_id, location=location)
    multimodal_model = GenerativeModel("gemini-2.0-flash-001")
    response = multimodal_model.generate_content(
        [
            Part.from_uri(
                "gs://generativeai-downloads/images/scones.jpg", mime_type="image/jpeg"
            ),
            "what is shown in this image?",
        ]
    )
    return response.text

project_id = "$ID"
location = "$REGION"

response = generate_text(project_id, location)
print(response)
EOF_CP

# 7. Menunggu 20 detik
sleep 20

# 8. Menjalankan skrip genai.py tiga kali
/usr/bin/python3 /home/student/genai.py
sleep 5
/usr/bin/python3 /home/student/genai.py
/usr/bin/python3 /home/student/genai.py