#!/bin/bash

# 1. Membuat Instance Compute Engine
gcloud compute instances create my-instance \
    --machine-type=e2-medium \
    --zone=$ZONE \
    --image-project=debian-cloud \
    --image-family=debian-11 \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-balanced \
    --create-disk=size=100GB,type=pd-standard,mode=rw,device-name=additional-disk \
    --tags=http-server

# 2. Membuat dan Menambahkan Disk Tambahan
gcloud compute disks create mydisk --size=200GB --zone=$ZONE
gcloud compute instances attach-disk my-instance --disk=mydisk --zone=$ZONE

# 3. Menunggu 15 detik
sleep 15

# 4. Menyiapkan Skrip untuk Instalasi Nginx
cat > prepare_disk.sh <<'EOF_END'
sudo apt update
sudo apt install nginx -y
sudo systemctl start nginx
EOF_END

# 5. Mengunggah Skrip ke Instance
gcloud compute scp prepare_disk.sh my-instance:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

# 6. Mengeksekusi Skrip di Instance
gcloud compute ssh my-instance --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"