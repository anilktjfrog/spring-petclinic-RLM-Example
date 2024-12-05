# SET meta-data to differentiate application category, such as application or internal-library
# export PACKAGE_CATEGORIES=(WEBAPP, SERVICE, LIBRARY, BASEIMAGE)
clear
# TOKEN SETUP
# jf c add --user=krishnam --interactive=true --url=https://psazuse.jfrog.io --overwrite=true 

# Config - Artifactory info
export JF_HOST="psazuse.jfrog.io"  JFROG_RT_USER="krishnam" JFROG_CLI_LOG_LEVEL="DEBUG" # JF_ACCESS_TOKEN="<GET_YOUR_OWN_KEY>"
export JF_RT_URL="https://${JF_HOST}" RT_REPO_VIRTUAL="krishnam-mvn-virtual"  

echo "JF_RT_URL: $JF_RT_URL \n JFROG_RT_USER: $JFROG_RT_USER \n JFROG_CLI_LOG_LEVEL: $JFROG_CLI_LOG_LEVEL \n "
## Config - project
### CLI
export BUILD_NAME="spring-petclinic" BUILD_ID="cmd.mvn.$(date '+%Y-%m-%d-%H-%M')" JAR_FINAL_NAME="cmd-spring-petclinic"

# MVN 
set -x # activate debugging from here
## Health check
echo "\n\n**** JF RT: ${JF_RT_URL}  ****\n\n" 
jf rt ping --url=${JF_RT_URL}/artifactory

### Jenkins
# export BUILD_NAME=${env.JOB_NAME} BUILD_ID=${env.BUILD_ID} 
# References: 
# https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#using-environment-variables 
# https://wiki.jenkins.io/JENKINS/Building+a+software+project 

echo " BUILD_NAME: $BUILD_NAME \n BUILD_ID: $BUILD_ID \n JFROG_CLI_LOG_LEVEL: $JFROG_CLI_LOG_LEVEL  \n RT_PROJECT_REPO: $RT_PROJECT_REPO  \n "
jf mvnc --global --repo-resolve-releases ${RT_REPO_VIRTUAL} --repo-resolve-snapshots ${RT_REPO_VIRTUAL} 

## Create Build
echo "\n\n**** MVN: Package ****\n\n" # --scan=true  -Djar.finalName=${JAR_FINAL_NAME}
# mvn dependency:purge-local-repository && mvn clean install -U
jf mvn clean install -DskipTests --build-name=${BUILD_NAME} --build-number=${BUILD_ID} --detailed-summary

# # setting build properties
# export job="b_github-action" org="b_ps" team="b_architecture" product="b_jfrog-saas"  # These properties were captured in Builds >> spring-petclinic >> version >> Environment tab

# Evidence on artifact. ref: https://github.com/jfrog/SwampUp2024/tree/126822b1f5cefbfb35616b8b4a4c56e3fe406f31/JFTD-113-RLM/evidence
VAR_EVD_SPEC="evd-sign.json"
#echo '{ "actor": "${{ github.actor }}", "date": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'" }' > $VAR_EVD_SPEC
echo '{ "actor": "krishnam", "date": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'" }' > $VAR_EVD_SPEC
cat $VAR_EVD_SPEC
jf evd create --package-name ${BUILD_NAME}} --package-version ${BUILD_ID} --predicate $VAR_EVD_SPEC --key "${{ secrets.PRIVATE_KEY }}" --predicate-type https://jfrog.com/evidence/signature/v1 
echo "🔎 Evidence attached: 'signature' 🔏 "


# ## bce:build-collect-env - Collect environment variables. Environment variables can be excluded using the build-publish command.
# jf rt bce ${BUILD_NAME} ${BUILD_ID}

# ## bag:build-add-git - Collect VCS details from git and add them to a build.
# jf rt bag ${BUILD_NAME} ${BUILD_ID}

# ## bp:build-publish - Publish build info
# echo "\n\n**** Build Info: Publish ****\n\n"
# jf rt bp ${BUILD_NAME} ${BUILD_ID} --detailed-summary=true

# # set-props
# echo "\n\n**** Props: set ****\n\n"  # These properties were captured Artifacts >> repo path 'spring-petclinic.---.jar' >> Properties
# jf rt sp "job=a_github-action;org=a_ps;team=a_architecture;product=a_jfrog-saas;build=maven;ts=ts-${BUILD_ID}" --build="${BUILD_NAME}/${BUILD_ID}"



set +x # stop debugging from here
echo "\n\n**** JF-CLI-MVN.SH - DONE at $(date '+%Y-%m-%d-%H-%M') ****\n\n"


sleep 3
echo "\n\n**** CLEAN UP ****\n\n"
rm -rf $VAR_RBv2_SPEC
rm -rf $VAR_BUILD_SCAN_INFO
rm -rf $VAR_RBv2_PROMO_INFO
rm -rf $VAR_RBv2_SCAN_INFO
rm -rf $VAR_EVD_SPEC

