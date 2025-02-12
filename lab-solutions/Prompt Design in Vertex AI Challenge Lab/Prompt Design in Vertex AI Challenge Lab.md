# [Secure BigLake Data: Challenge Lab](https://www.cloudskillsboost.google/focuses/64458?parent=catalog)

## ⚠️ **Disclaimer:**
Script dan panduan ini disediakan untuk tujuan edukasi agar Anda dapat memahami proses lab dengan lebih baik. Sebelum menggunakannya, disarankan untuk meninjau setiap langkah guna memperoleh pemahaman yang lebih mendalam. Pastikan untuk mematuhi ketentuan layanan Qwiklabs, karena tujuan utamanya adalah mendukung pengalaman belajar Anda.


### **Task 1**
1. Masuk ke `Freeform` [disini](https://console.cloud.google.com/vertex-ai/studio/freeform) atau melalui Vertex AI > Prompt Managemeng > Create Prompt > Freeform.
2. Download gambar dari Task 1, lalu upload tekan `Insert Media`.
3. Copy text ini `Short, descriptive text inspired by the image.` dan paste di Prompt.
4. Pilih Model `gemini-1.5-pro-001` dan Region Sesuai di Task 1.
5. Run Prompt.
6. Save prompt dengan nama file `Cymbal Product Analysis` dan tunggu prosesnya hingga selesai.

Tampilan dari Task 1 ![Task 1](https://raw.githubusercontent.com/andregregs/juaragcp-s11/main/lab-solutions/Prompt%20Design%20in%20Vertex%20AI%20Challenge%20Lab/Cymbal%20Product%20Analysis.png)

### **Task 2**
1. Masuk ke `Freeform` [disini](https://console.cloud.google.com/vertex-ai/studio/freeform) atau melalui Vertex AI > Prompt Managemeng > Create Prompt > Freeform.
2. Copy text ini dan masukkan System Instruction:
```Cymbal Direct is partnering with an outdoor gear retailer. They're launching a new line of products designed to encourage young people to explore the outdoors. Help them create catchy taglines for this product line.```
3. Tekan Add Examples dan copy text ini:

| Input                                                                                                                                     | Output                                             |
|-------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------|
| Write a tagline for a durable backpack designed for hikers that makes them feel prepared. Consider styles like minimalist.                 | Built for the Journey: Your Adventure Essentials.  |
| Write a tagline for an eco-friendly rain jacket designed for families that makes them feel connected. Consider styles like playful, with a touch of humor. | Explore More, Worry Less. Weather the fun together! |

![Add Examples](https://raw.githubusercontent.com/andregregs/juaragcp-s11/main/lab-solutions/Prompt%20Design%20in%20Vertex%20AI%20Challenge%20Lab/Add%20Examples.png)

4. Pilih Model `gemini-1.5-pro-001` dan Region Sesuai di Task 2.
5. Masukkan Text ini `Write a tagline for a lightweight tent designed for seasoned explorers that makes them feel free. Consider styles like poetic.`.
6. Ubah Prompt Name menjadi `Cymbal Tagline Generator Template`.
7. Run Prompt.
8. Turn Off Auto Save kemudian Save file.

Tampilan dari Task 2 ![Task 2](https://raw.githubusercontent.com/andregregs/juaragcp-s11/main/lab-solutions/Prompt%20Design%20in%20Vertex%20AI%20Challenge%20Lab/Cymbal%20Tagline%20Generator%20Template.png)

### **Task 3**
1. Masuk ke Workbench [disini](https://console.cloud.google.com/vertex-ai/workbench/instances) atau melalui Vertex AI > Workbench.
2. Pada bagian Instances, tekan `OPEN JUPYTERLAB`.
3. Download File [image-analysis.ipynb](https://github.com/andregregs/juaragcp-s11/blob/main/lab-solutions/Prompt%20Design%20in%20Vertex%20AI%20Challenge%20Lab/image-analysis.ipynb) dan file [tagline-generator](https://github.com/andregregs/juaragcp-s11/blob/main/lab-solutions/Prompt%20Design%20in%20Vertex%20AI%20Challenge%20Lab/tagline-generator.ipynb).
4. Upload kedua file tersebut di Jupyterlab.
5. Jalankan file `image-analysis.ipynb` terlebih dahulu dan ubah PROJECT ID dan location sesuai dengan yg ada di instruksi.
6. Jalankan file `tagline-generator.ipynb`.
