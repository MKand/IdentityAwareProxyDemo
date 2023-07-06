# Enable Cloudbuild API
echo -e "\e[95mEnabling required APIs in ${PROJECT_ID}\e[0m"
gcloud services enable cloudresourcemanager.googleapis.com cloudbuild.googleapis.com storage.googleapis.com artifactregistry.googleapis.com beyondcorp.googleapis.com cloudapis.googleapis.com compute.googleapis.com iap.googleapis.com run.googleapis.com

# Make cloudbiuld SA roles/owner for PROJECT_ID
# TODO: Make these permissions more granular to precisely what is required by cloudbuild
echo -e "\e[95mAssigning Cloudbuild Service Account roles/owner in ${PROJECT_ID}\e[0m"
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format 'value(projectNumber)')
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com --role roles/owner

# Start main build
echo -e "\e[95mStarting Cloudbuild to create infrastructure using ${BUILD}...\e[0m"
[[ "${DESTROY}" != "true" ]] && gcloud builds submit --config=builds/infra_terraform.yaml --substitutions=_PROJECT_ID=${PROJECT_ID} --async
#[[ "${DESTROY}" == "true" ]] && gcloud builds submit --config=builds/infra_terraform_destroy.yaml --substitutions=_PROJECT_ID=${PROJECT_ID} --async

echo -e "\e[95mYou can view the Cloudbuild status through https://console.cloud.google.com/cloud-build\e[0m"
