# SET meta-data to differentiate application category, such as application or internal-library
# export PACKAGE_CATEGORIES=(WEBAPP, SERVICE, LIBRARY, BASEIMAGE)
clear
# TOKEN SETUP
# jf c add --user=krishnam --interactive=true --url=https://psazuse.jfrog.io --overwrite=true 

# Config - Artifactory info
export JF_RT_URL="https://psazuse.jfrog.io" JFROG_NAME="psazuse" JFROG_RT_USER="krishnam" JFROG_CLI_LOG_LEVEL="DEBUG" # JF_ACCESS_TOKEN="<GET_YOUR_OWN_KEY>"
export RT_PROJECT_REPO="krishnam-mvn"

echo " JFROG_NAME: $JFROG_NAME \n JF_RT_URL: $JF_RT_URL \n JFROG_RT_USER: $JFROG_RT_USER \n JFROG_CLI_LOG_LEVEL: $JFROG_CLI_LOG_LEVEL \n "

# MVN 
## Config - project
### CLI
export BUILD_NAME="spring-petclinic-rbv2-pcondition" BUILD_ID="cmd.$(date '+%Y-%m-%d-%H-%M')" PACKAGE_CATEGORY="WEBAPP" RT_PROJECT_RB_SIGNING_KEY="krishnam"

### Jenkins
# export BUILD_NAME=${env.JOB_NAME} BUILD_ID=${env.BUILD_ID} PACKAGE_CATEGORY="WEBAPP"
# References: 
# https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#using-environment-variables 
# https://wiki.jenkins.io/JENKINS/Building+a+software+project 

echo " BUILD_NAME: $BUILD_NAME \n BUILD_ID: $BUILD_ID \n JFROG_CLI_LOG_LEVEL: $JFROG_CLI_LOG_LEVEL  \n RT_PROJECT_REPO: $RT_PROJECT_REPO  \n "

jf mvnc --server-id-resolve ${JFROG_NAME} --server-id-deploy ${JFROG_NAME} --repo-resolve-releases ${RT_PROJECT_REPO}-virtual --repo-resolve-snapshots ${RT_PROJECT_REPO}-virtual --repo-deploy-releases ${RT_PROJECT_REPO}-local --repo-deploy-snapshots ${RT_PROJECT_REPO}-dev-local

## Create Build
echo "\n\n**** MVN: Package ****\n\n" # --scan=true
jf mvn clean install -DskipTests=true --build-name=${BUILD_NAME} --build-number=${BUILD_ID} --detailed-summary=true 

## bce:build-collect-env - Collect environment variables. Environment variables can be excluded using the build-publish command.
jf rt bce ${BUILD_NAME} ${BUILD_ID}

## bag:build-add-git - Collect VCS details from git and add them to a build.
jf rt bag ${BUILD_NAME} ${BUILD_ID}

## bp:build-publish - Publish build info
echo "\n\n**** Build Info: Publish ****\n\n"
jf rt bp ${BUILD_NAME} ${BUILD_ID} --detailed-summary=true

## RBv2: release bundle - create
# ref: https://docs.jfrog-applications.jfrog.io/jfrog-applications/jfrog-cli/cli-for-jfrog-artifactory/release-lifecycle-management
echo "\n\n**** RBv2: Create ****\n\n"
echo " BUILD_NAME: $BUILD_NAME \n BUILD_ID: $BUILD_ID \n RT_PROJECT_REPO: $RT_PROJECT_REPO  \n RT_PROJECT_RB_SIGNING_KEY: $RT_PROJECT_RB_SIGNING_KEY  \n "

  # create spec
echo "{ \"files\": [ {\"build\": \"${BUILD_NAME}/${BUILD_ID}\", \"includeDeps\": \"false\" } ] }"  > RBv2-SPEC-${BUILD_ID}.json
#echo "{ \"files\": [ {\"build\": \"${BUILD_NAME}/${BUILD_ID}\", \"props\": \"build_name=${BUILD_NAME};build_id=${BUILD_ID};PACKAGE_CATEGORY=${PACKAGE_CATEGORY};state=new\" } ] }"  > RBv2-SPEC-${BUILD_ID}.json
echo "\n" && cat RBv2-SPEC-${BUILD_ID}.json && echo "\n"

  # create RB to state=NEW
jf rbc ${BUILD_NAME} ${BUILD_ID} --sync="true" --access-token="${JF_ACCESS_TOKEN}" --url="${JF_RT_URL}" --signing-key="${RT_PROJECT_RB_SIGNING_KEY}" --spec="RBv2-SPEC-${BUILD_ID}.json" --server-id="psazuse" # --spec-vars="build_name=${BUILD_NAME};build_id=${BUILD_ID};PACKAGE_CATEGORY=${PACKAGE_CATEGORY};state=new" 

## RBv2: release bundle - DEV promote
echo "\n\n**** RBv2: Promoted to DEV ****\n\n"
jf rbp --sync="true" --access-token="${JF_ACCESS_TOKEN}" --url="${JF_RT_URL}" --signing-key="${RT_PROJECT_RB_SIGNING_KEY}" --server-id="psazuse" ${BUILD_NAME} ${BUILD_ID} DEV 

sleep 5

echo "\n\n**** Get BuilfInfo's Package category & RBv2 state ****\n\n"
## AQL: if RBv2=DEV & BuildInfo package category = Web, promote to PROD else promote to QA
#BP_RESP_DATA=$(curl --location '${JF_RT_URL}/artifactory/api/build/${BUILD_NAME}/${BUILD_ID}' --header 'Content-Type:  application/json' --header 'Authorization: Bearer ${JF_ACCESS_TOKEN}'  | jq -r '.buildInfo.properties')
export BUILDINFO_PACKAGE_CATEGORY=$(jf rt curl /api/build/${BUILD_NAME}/${BUILD_ID}?async=false | jq -r '.buildInfo.properties."buildInfo.env.PACKAGE_CATEGORY"')
# jf rt curl /api/build/spring-petclinic-rbv2/cmd.2024-08-30-21-17 | jq -r '.buildInfo.properties."buildInfo.env.PACKAGE_CATEGORY"'
echo " BuildInfo Package Category =  $BUILDINFO_PACKAGE_CATEGORY \n"

# `curl -v -G '${JF_RT_URL}/lifecycle/api/v2/promotion/records/${BUILD_NAME}/${BUILD_ID}?async=false' -H 'Content-Type:  application/json' -H 'Authorization: Bearer ${JF_ACCESS_TOKEN}'` > RBv2_STATUS-${BUILD_ID}.json

# export RB2_STATUS=$(echo $RB2_STATUS | jq -r '.promotions[0].environment')
echo "JF_ACCESS_TOKEN = ${JF_ACCESS_TOKEN}"

# refer, JF CLI issue at https://github.com/jfrog/jfrog-cli/issues/2677 
export RB2_STATUS_RESP=$(curl -v -G ${JF_RT_URL}/lifecycle/api/v2/promotion/records/${BUILD_NAME}/${BUILD_ID}?async=false -H 'Content-Type:  application/json' -H "Authorization: Bearer ${JF_ACCESS_TOKEN}")

echo $RB2_STATUS_RESP > RBv2_STATUS-${BUILD_ID}.json

export RB2_STATUS=$(echo $RB2_STATUS_RESP | jq -r '.promotions[0].environment')
echo " Release Bundle state =  $RB2_STATUS "

# rm -rf RBv2-SPEC-${BUILD_ID}.json
# rm -rf RBv2_STATUS-${BUILD_ID}.json

if [[ -n $BUILDINFO_PACKAGE_CATEGORY ]] ; then
  if  [[ "WEBAPP" == "${BUILDINFO_PACKAGE_CATEGORY}" ]] && [[ "DEV" == "${RB2_STATUS}" ]] ; then 
    echo "\n\n**** RBv2: Promoted to NEW --> DEV --> PROD ****\n\n"
    jf rbp --sync="true" --access-token="${JF_ACCESS_TOKEN}" --url="${JF_RT_URL}" --signing-key="${RT_PROJECT_RB_SIGNING_KEY}" --server-id="psazuse" ${BUILD_NAME} ${BUILD_ID} PROD  
  else 
    echo "\n\n**** RBv2: Promoted to NEW --> DEV --> QA ****\n\n"
    jf rbp --sync="true" --access-token="${JF_ACCESS_TOKEN}" --url="${JF_RT_URL}" --signing-key="${RT_PROJECT_RB_SIGNING_KEY}" --server-id="psazuse" ${BUILD_NAME} ${BUILD_ID} QA  
  fi
fi

echo "\n\n**** DONE ****\n\n"