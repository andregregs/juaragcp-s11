# [Get Started with Sensitive Data Protection: Challenge Lab](https://www.cloudskillsboost.google/course_templates/750/labs/510997)


## 🚀 **Steps to Execute in Cloud Shell:**
### Run the following Commands in CloudShell
```
curl -LO raw.githubusercontent.com/andregregs/juaragcp-s11/refs/heads/main/lab-solutions/Get%20Started%20with%20Sensitive%20Data%20Protection%20Challenge%20Lab/script-1.sh

sudo chmod +x script-1.sh

./script-1.sh
```
1. Klik Structured Data Template URL yang muncul di terminal.
2. Pada bagian Configure de-identification, tekan **+ADD TRANSFORMATION RULE**.
3. Pada Field(s) or column(s) to transform, masukkan **message**.
4. Pada Transformation type, pilih **Match on infoType**.
5. Tekan **ADD TRANSFORMATION**, lalu pada Transformation method, pilih **Replace with infoType name**.
6. Tekan Save untuk menyimpan konfigurasi.

```
curl -LO raw.githubusercontent.com/andregregs/juaragcp-s11/refs/heads/main/lab-solutions/Get%20Started%20with%20Sensitive%20Data%20Protection%20Challenge%20Lab/script-2.sh

sudo chmod +x script-2.sh

./script-2.sh

```
1. Klik Unstructured Data Template URL yang muncul di terminal.
2. Pada bagian Configure de-identification, tekan **Transformation Rule**.
3. Pada InfoTypes to transform, pilih **Any detected infoTypes defined in an inspection template or inspect config that are not specified in other rules**
4. Tekan Save untuk menyimpan konfigurasi.