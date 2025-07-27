#!/bin/bash

# 1. Mendapatkan Project ID
ID="$(gcloud projects list --format='value(PROJECT_ID)')"

# 2. Membuat file Python untuk generate bouquet image menggunakan Vertex AI
cat > GenerateImage.py <<EOF_CP
import argparse
import vertexai
from vertexai.preview.vision_models import ImageGenerationModel

def generate_bouquet_image(prompt):
    """
    Generate a bouquet image using the imagen-3.0-generate-002 model
    """
    project_id = '$ID'
    location = '$REGION'
    
    vertexai.init(project=project_id, location=location)
    model = ImageGenerationModel.from_pretrained("imagen-3.0-generate-002")
    images = model.generate_images(
        prompt=prompt,
        number_of_images=1,
        seed=1,
        add_watermark=False,
    )
    
    # Save image locally
    output_file = 'bouquet.jpeg'
    images[0].save(location=output_file)
    print(f"Bouquet image saved as: {output_file}")
    return images, output_file

# Generate bouquet with the specified prompt
prompt = "Create an image containing a bouquet of 2 sunflowers and 3 roses"
generate_bouquet_image(prompt)
EOF_CP

# 3. Menunggu 20 detik
sleep 20

# 4. Menjalankan skrip GenerateImage.py untuk membuat bouquet
/usr/bin/python3 /home/student/GenerateImage.py

# 5. Menunggu 10 detik
sleep 10

# 6. Membuat file Python untuk analyze bouquet image menggunakan Vertex AI
cat > genai.py <<EOF_CP
import vertexai
from vertexai.generative_models import GenerativeModel, Part
import os

def analyze_bouquet_image(image_path):
    """
    Analyze bouquet image and generate birthday wishes using gemini-2.0-flash-001
    with streaming enabled
    """
    project_id = "$ID"
    location = "$REGION"
    
    vertexai.init(project=project_id, location=location)
    multimodal_model = GenerativeModel("gemini-2.0-flash-001")
    
    # Check if image file exists
    if not os.path.exists(image_path):
        print(f"Error: Image file {image_path} not found")
        return None
    
    # Load the local image
    with open(image_path, 'rb') as img_file:
        image_data = img_file.read()
    
    # Create the prompt for birthday wishes based on the bouquet
    prompt = """
    Analyze this bouquet image and generate personalized birthday wishes based on the flowers you see. 
    Consider the types of flowers, colors, and arrangement to create warm, heartfelt birthday messages 
    that reference the specific flowers in the bouquet.
    """
    
    # Generate content with streaming enabled
    response = multimodal_model.generate_content(
        [
            Part.from_data(data=image_data, mime_type="image/jpeg"),
            prompt
        ],
        stream=True  # Enable streaming
    )
    
    print("Generated Birthday Wishes (Streaming):")
    print("-" * 50)
    
    full_response = ""
    for chunk in response:
        if chunk.text:
            print(chunk.text, end="", flush=True)
            full_response += chunk.text
    
    print("\n" + "-" * 50)
    return full_response

# Analyze the generated bouquet image
image_path = "/home/student/bouquet.jpeg"
analyze_bouquet_image(image_path)
EOF_CP

# 7. Menunggu 20 detik
sleep 20

# 8. Menjalankan skrip genai.py untuk analyze bouquet
/usr/bin/python3 /home/student/genai.py

# 9. Create log file to confirm completion
echo "Bouquet analysis completed at $(date)" > /home/student/analysis_log.txt