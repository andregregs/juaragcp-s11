#!/bin/bash

# Define the necessary variables for the process
#----------------------------------------------------start--------------------------------------------------#

# Step 1: Start the execution process
echo "Starting Execution"

# Step 2: Create the redact request JSON file
cat > redact-request.json <<EOF_END
{
	"item": {
		"value": "Please update my records with the following information:\n Email address: foo@example.com,\nNational Provider Identifier: 1245319599"
	},
	"deidentifyConfig": {
		"infoTypeTransformations": {
			"transformations": [{
				"primitiveTransformation": {
					"replaceWithInfoTypeConfig": {}
				}
			}]
		}
	},
	"inspectConfig": {
		"infoTypes": [{
				"name": "EMAIL_ADDRESS"
			},
			{
				"name": "US_HEALTHCARE_NPI"
			}
		]
	}
}
EOF_END

# Step 3: Send the redact request to the DLP API
curl -s \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/content:deidentify \
  -d @redact-request.json -o redact-response.txt

# Step 4: Upload the redact response to Google Cloud Storage
echo "Uploading redact-response.txt to Google Cloud Storage..."
gsutil cp redact-response.txt gs://$DEVSHELL_PROJECT_ID-redact

# Step 5: Create a template for structured data redaction
cat > template.json <<EOF_END
{
	"deidentifyTemplate": {
	  "deidentifyConfig": {
		"recordTransformations": {
		  "fieldTransformations": [
			{
			  "fields": [
				{
				  "name": "bank name"
				},
				{
				  "name": "zip code"
				}
			  ],
			  "primitiveTransformation": {
				"characterMaskConfig": {
				  "maskingCharacter": "#"
				}
			  }
			}
		  ]
		}
	  },
	  "displayName": "structured_data_template"
	},
	"locationId": "global",
	"templateId": "structured_data_template"
}
EOF_END

# Step 6: Send the structured data template to DLP API
echo "Sending structured_data_template to DLP API..."
curl -s \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json" \
https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/deidentifyTemplates \
-d @template.json

# Step 7: Create a template for unstructured data redaction
cat > template.json <<'EOF_END'
{
  "deidentifyTemplate": {
    "deidentifyConfig": {
      "infoTypeTransformations": {
        "transformations": [
          {
            "infoTypes": [
              {
                "name": ""
              }
            ],
            "primitiveTransformation": {
              "replaceConfig": {
                "newValue": {
                  "stringValue": "[redacted]"
                }
              }
            }
          }
        ]
      }
    },
    "displayName": "unstructured_data_template"
  },
  "templateId": "unstructured_data_template",
  "locationId": "global"
}
EOF_END

# Step 8: Send the unstructured data template to DLP API
echo "Sending unstructured_data_template to DLP API..."
curl -s \
-H "Authorization: Bearer $(gcloud auth application-default print-access-token)" \
-H "Content-Type: application/json" \
https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/deidentifyTemplates \
-d @template.json

# Step 9: Output the URLs for the templates
echo "Structured Data Template URL:"
echo "https://console.cloud.google.com/security/sensitive-data-protection/projects/$DEVSHELL_PROJECT_ID/locations/global/deidentifyTemplates/structured_data_template/edit?project=$DEVSHELL_PROJECT_ID"

echo "Unstructured Data Template URL:"
echo "https://console.cloud.google.com/security/sensitive-data-protection/projects/$DEVSHELL_PROJECT_ID/locations/global/deidentifyTemplates/unstructured_data_template/edit?project=$DEVSHELL_PROJECT_ID"
