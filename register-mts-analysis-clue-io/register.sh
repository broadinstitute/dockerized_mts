#!/usr/bin/env bash
ROLE_ID="cmap_core"
APPROVED="false"

while test $# -gt 0; do
  case "$1" in
    -f| --compound_key_file)
      shift
      COMPOUND_KEY_JSON=$1
      ;;
    -s|--s3_location)
      shift
      S3_LOCATION=$1
      ;;
    -i|--build_id)
      shift
      BUILD_ID=$1
      ;;
    -p|--project_name)
      shift
      PROJECT_NAME=$1
      ;;
    -r|--role_id)
      shift
      ROLE_ID=$1
      APPROVED="true"
      ;;
    *)
      printf "Unknown parameter: %s \n" "$1"
      shift
      ;;
  esac
  shift
done
NL=$'\n'
errorMessage=""

if [[ ! -z "${S3_LOCATION}" && ! -z "${BUILD_ID}" ]]
then
    if [[ ! -z "${AWS_BATCH_JOB_ARRAY_INDEX}" ]]
    then
        batch_index=${AWS_BATCH_JOB_ARRAY_INDEX}
        if test -f "${COMPOUND_KEY_JSON}"
        then
            project=$(cat "${COMPOUND_KEY_JSON}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
            PROJECT_NAME="${project}"
            INDEX_PAGE="${S3_LOCATION}"/"${PROJECT_NAME,,}"/index.html
        elif [[ ! -z "${COMPOUND_KEY_JSON}" ]]
        then
            project=$(echo "${COMPOUND_KEY_JSON}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
            role=$(echo "${COMPOUND_KEY_JSON}" | jq -r --argjson index ${batch_index} '.[$index].role')
            PROJECT_NAME="${project}"
            ROLE_ID="${role}"
            INDEX_PAGE="${S3_LOCATION}"/"${PROJECT_NAME,,}"/index.html
         else
            errorMessage="$errorMessage Array jobs must follow the following pattern${NL}"
            errorMessage="$errorMessage register -f <COMPOUND_KEY_JSON> -s <S3_LOCATION> -i <BUILD_ID>${NL}"
        fi
    elif [[ ! -z "${COMPOUND_KEY_JSON}" ]]
    then
        batch_index=0
        if test -f "${COMPOUND_KEY_JSON}"
        then
            project=$(cat "${COMPOUND_KEY_JSON}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
        else
            project=$(echo "${COMPOUND_KEY_JSON}" | jq -r --argjson index ${batch_index} '.[$index].x_project_id')
            role=$(echo "${COMPOUND_KEY_JSON}" | jq -r --argjson index ${batch_index} '.[$index].role')
            ROLE_ID="${role}"
        fi
        PROJECT_NAME="${project}"
        INDEX_PAGE="${S3_LOCATION}"/"${PROJECT_NAME,,}"/index.html
    elif [[ ! -z "${PROJECT_NAME}" ]]
    then
        INDEX_PAGE="${S3_LOCATION}"/"${PROJECT_NAME,,}"/index.html
    else
        errorMessage="$errorMessage Invoke with the following pattern${NL}"
        errorMessage="$errorMessage register -s <S3_LOCATION> -i <BUILD_ID> -p <PROJECT_NAME>${NL}"
    fi
else
    errorMessage="$errorMessage Invoke with the following pattern${NL}"
    errorMessage="$errorMessage register -s <S3_LOCATION> -i <BUILD_ID> [-p PROJECT_NAME | -f COMPOUND_KEY_JSON]${NL}"
fi

echo PROJECT_NAME: "${PROJECT_NAME}" INDEX_PAGE: "${INDEX_PAGE}"  BUILD_ID: "${BUILD_ID}"
echo ROLE_ID: "${ROLE_ID}" APPROVED: "${APPROVED}"

if [[ -z "${errorMessage}" ]]
then
    echo node ./index.js "${PROJECT_NAME}" "${INDEX_PAGE}"  "${BUILD_ID}" "${ROLE_ID}" "${APPROVED}"
    node ./index.js "${PROJECT_NAME}" "${INDEX_PAGE}"  "${BUILD_ID}" "${ROLE_ID}" "${APPROVED}"
else
    echo "${errorMessage}"
    exit -1
fi

exit_code=$?
exit ${exit_code}
