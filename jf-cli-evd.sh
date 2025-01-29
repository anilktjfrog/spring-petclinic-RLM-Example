clear
# TOKEN SETUP
# jf c add --user=krishnamanchikalapudi --interactive=true --url=https://psazuse.jfrog.io --overwrite=true 

# Config - Artifactory info
export JF_HOST="psazuse.jfrog.io"  JFROG_RT_USER="krishnamanchikalapudi" JFROG_CLI_LOG_LEVEL="DEBUG" # JF_ACCESS_TOKEN="<GET_YOUR_OWN_KEY>"
export JF_RT_URL="https://${JF_HOST}"
export RT_REPO_VIRTUAL="krishnam-mvn-virtual" RBv2_SIGNING_KEY="krishnam"

echo "JF_RT_URL: $JF_RT_URL \n JFROG_RT_USER: $JFROG_RT_USER \n JFROG_CLI_LOG_LEVEL: $JFROG_CLI_LOG_LEVEL \n "

## Health check
jf config show
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
jf mvn clean install -DskipTests=true -Denforcer.skip=true --build-name=${BUILD_NAME} --build-number=${BUILD_ID} --detailed-summary=true 

## bce:build-collect-env - Collect environment variables. Environment variables can be excluded using the build-publish command.
jf rt bce ${BUILD_NAME} ${BUILD_ID}

## bag:build-add-git - Collect VCS details from git and add them to a build.
jf rt bag ${BUILD_NAME} ${BUILD_ID}

## bp:build-publish - Publish build info
echo "\n\n**** Build Info: Publish ****\n\n"
jf rt bp ${BUILD_NAME} ${BUILD_ID} --detailed-summary


# Evidence on build. Reference https://jfrog.com/help/r/jfrog-artifactory-documentation/evidence-management
echo "\n\n**** Evidence: for Build ****\n\n"
ls -lrt ~/.ssh/jfrog_evd_*
export KRISHNAM_JFROG_EVD_PRIVATEKEY="$(cat ~/.ssh/jfrog_evd_private.pem)" # ref: Create an RSA Key Pair https://jfrog.com/help/r/jfrog-artifactory-documentation/evidence-setup
export KRISHNAM_JFROG_EVD_PUBLICKEY="$(cat ~/.ssh/jfrog_evd_public.pem)"
export VAR_EVD_ARTIFACT_JSON="evd-artfact-${BUILD_ID}.json" 
echo "{ \"actor\": \"krishnamanchikalapudi\", \"date\": \"$(date '+%Y-%m-%dT%H:%M:%SZ')\", \"build_name\": \"${BUILD_NAME}\", \"build_id\": \"${BUILD_ID}\", \"Job\":\"CMD SH Script\", \"Evd\":\"Build\" }" > ${VAR_EVD_ARTIFACT_JSON}
cat ./${VAR_EVD_ARTIFACT_JSON}

# jf evd create --build-name spring-petclinic --build-number cmd.evd.2025-01-28-16-28 --predicate="$(cat ./evd-artfact-cmd.evd.2025-01-28-16-28.json)" --predicate-type="https://dayone.dev/signature" --key "$(cat ~/.ssh/jfrog_evd_private.pem)"
jf evd create --build-name="${BUILD_NAME}" --build-number="${BUILD_ID}" --predicate="$(cat ./VAR_EVD_ARTIFACT_JSON)" --predicate-type="https://dayone.dev/signature" --key ${KRISHNAM_JFROG_EVD_PRIVATEKEY} key-name="KRISHNAM_JFROG_EVD_PUBLICKEY"
echo "🔎 Evidence attached on Build: signature 🔏 "


sleep 3
echo "\n\n**** CLEAN UP ****\n\n"
ls evd-*.json
# rm -rf ${VAR_EVD_ARTIFACT_JSON}

set +x # stop debugging from here
echo "\n\n**** JF-CLI-EVD-RBV2.SH - DONE at $(date '+%Y-%m-%d-%H-%M') ****\n\n"