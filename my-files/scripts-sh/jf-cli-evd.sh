clear
# TOKEN SETUP
# jf c add --user=krishnam --interactive=true --url=https://psazuse.jfrog.io --overwrite=true 

# Config - Artifactory info
export JF_HOST="psazuse.jfrog.io"  JFROG_RT_USER="krishnam" JFROG_CLI_LOG_LEVEL="DEBUG" # JF_ACCESS_TOKEN="<GET_YOUR_OWN_KEY>"
export JF_RT_URL="https://${JF_HOST}"
export RT_REPO_VIRTUAL="krishnam-mvn-virtual" RBv2_SIGNING_KEY="krishnam"

echo "JF_RT_URL: $JF_RT_URL \n JFROG_RT_USER: $JFROG_RT_USER \n JFROG_CLI_LOG_LEVEL: $JFROG_CLI_LOG_LEVEL \n "

## Health check
jf rt ping --url=${JF_RT_URL}/artifactory

# MVN 
set -x # activate debugging from here
## Config - project
### CLI
export BUILD_NAME="spring-petclinic" BUILD_ID="cmd.evd.$(date '+%Y-%m-%d-%H-%M')" 

### Jenkins
# export BUILD_NAME=${env.JOB_NAME} BUILD_ID=${env.BUILD_ID} 
# References: 
# https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#using-environment-variables 
# https://wiki.jenkins.io/JENKINS/Building+a+software+project 

echo " BUILD_NAME: $BUILD_NAME \n BUILD_ID: $BUILD_ID \n JFROG_CLI_LOG_LEVEL: $JFROG_CLI_LOG_LEVEL  \n RT_REPO_VIRTUAL: $RT_REPO_VIRTUAL  \n "

jf mvnc --global --repo-resolve-releases ${RT_REPO_VIRTUAL} --repo-resolve-snapshots ${RT_REPO_VIRTUAL} 

## Create Build
echo "\n\n**** MVN: Package ****\n\n" # --scan=true
jf mvn clean install -DskipTests=true --build-name=${BUILD_NAME} --build-number=${BUILD_ID} --detailed-summary=true 

## bce:build-collect-env - Collect environment variables. Environment variables can be excluded using the build-publish command.
jf rt bce ${BUILD_NAME} ${BUILD_ID}

## bag:build-add-git - Collect VCS details from git and add them to a build.
jf rt bag ${BUILD_NAME} ${BUILD_ID}

## bp:build-publish - Publish build info
echo "\n\n**** Build Info: Publish ****\n\n"
jf rt bp ${BUILD_NAME} ${BUILD_ID} --detailed-summary


# Evidence on build
echo "\n\n**** Evidence: for Build ****\n\n"
export VAR_EVD_SIGN="evd-sign-${BUILD_ID}.json" 
echo "{ \"actor\": \"krishnamanchikalapudi\", \"date\": \"$(date '+%Y-%m-%dT%H:%M:%SZ')\", \"build_name\": \"${BUILD_NAME}\", \"build_id\": \"${BUILD_ID}\", \"Job\":\"CMD SH Script\", \"Evd\":\"Build\" }" > ${VAR_EVD_SIGN}
cat ./${VAR_EVD_SIGN}

jf evd create --access-token="${JF_ACCESS_TOKEN}" --url="${JF_RT_URL}" --server-id="psazuse" --build-name ${BUILD_NAME} --build-number ${BUILD_ID} --predicate "./${VAR_EVD_SIGN}" --predicate-type "https://dayone.dev/signature" --key "${RBv2_SIGNING_KEY}"
echo '🔎 Evidence attached on Build: `signature` 🔏 '


sleep 3
echo "\n\n**** CLEAN UP ****\n\n"
rm -rf $VAR_RBv2_SPEC
rm -rf ${VAR_EVD_SIGN}

set +x # stop debugging from here
echo "\n\n**** JF-CLI-EVD-RBV2.SH - DONE at $(date '+%Y-%m-%d-%H-%M') ****\n\n"