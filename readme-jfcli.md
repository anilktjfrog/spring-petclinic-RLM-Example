# Spring PetClinic Sample Application using JFrog CLI

## Prerequisites
- Read and understand the PetClinic application original documentation: [ReadME.MD](readme-original.md)
- Read and understand the PetClinic application jenkins pipeline documentation: [ReadME.MD](readme.md)

## Objective
Develop a DevOps pipeline to automate tasks such as code compile, unit testing, creation of container, and upload of artifacts to a repository. This will streamline the software development process using JFrog CLI.

Note: This process with not deploy to the envionrmnet platform. 

## Jenkins
### GitHub Actions using JF CLI

[![JF-CLI with Maven](https://github.com/krishnamanchikalapudi/spring-petclinic/actions/workflows/jfcli-mvn.yml/badge.svg?branch=main)](https://github.com/krishnamanchikalapudi/spring-petclinic/actions/workflows/jfcli-mvn.yml)

#### GitHub Actions steps: Docker Package, Build Info (SBOM), Release Bundle v2
- [pipeline file: GitHub Actions for Docker build](./github/jfcli-docker.yml)
- [![Walk through demo](https://img.youtube.com/vi/?/0.jpg)](https://www.youtube.com/watch?v=)

#### GitHub Actions steps: MVN Package, Build Info (SBOM), Release Bundle v2
- [pipeline file: GitHub Actions for MVN build](./github/jfcli-mvn.yml)
- [![Walk through demo](https://img.youtube.com/vi/?/0.jpg)](https://www.youtube.com/watch?v=)
#### Reference: Jenkins to GitHub Actions
- [migrating from jenkins to github actions](https://docs.github.com/en/actions/migrating-to-github-actions/manually-migrating-to-github-actions/migrating-from-jenkins-to-github-actions)
#### Error solutions
- <details><summary>Error: Exchanging JSON web token with an access token failed: getaddrinfo EAI_AGAIN access</summary>
    It is possbile that JF_RT_URL might be a NULL value
</details>


### DOCKER using JF CLI
### Pipeline Flow
<img src="./DevSecOps-Docker.svg">

- [![Walk through demo](https://img.youtube.com/vi/I28Qv_1oIsk/0.jpg)](https://www.youtube.com/watch?v=I28Qv_1oIsk)
#### DevOps steps: Package, Build Info (SBOM), Release Bundle v2
- [pipeline file: Jenkinsfile.jfrog-cli.docker](./Jenkinsfile.jfrog-cli.docker)
- [![Walk through demo](https://img.youtube.com/vi/60P9nerD5Ig/0.jpg)](https://www.youtube.com/watch?v=60P9nerD5Ig)

### MAVEN  using JF CLI
### Pipeline Flow
<img src="./DevSecOps-mvn.svg">

- [![Walk through demo](https://img.youtube.com/vi/uSpKVVXIZW0/0.jpg)](https://www.youtube.com/watch?v=uSpKVVXIZW0)
#### Package DevOps steps
- [pipeline file: Jenkinsfile.jfrog-cli.mvn](./Jenkinsfile.jfrog-cli.mvn)
- [![Walk through demo](https://img.youtube.com/vi/cHC79tWz8d4/0.jpg)](https://www.youtube.com/watch?v=cHC79tWz8d4)
#### SBOM
- [pipeline file: Jenkinsfile.jfrog-cli.mvn](./Jenkinsfile.mvn.buildInfo.jfrog-cli)
- [![Walk through demo](https://img.youtube.com/vi/Sm4vWhPsvAY/0.jpg)](https://www.youtube.com/watch?v=Sm4vWhPsvAY)
#### Release Bundle v2 - Create
- [pipeline file: Jenkinsfile.jfrog-cli.mvn](./Jenkinsfile.jfrog-cli.mvn)
- [![Walk through demo](https://img.youtube.com/vi/zap2gfYA3Vs/0.jpg)](https://www.youtube.com/watch?v=zap2gfYA3Vs)
#### Release Bundle v2 - Promote
- [pipeline file: Jenkinsfile.jfrog-cli.mvn](./Jenkinsfile.jfrog-cli.mvn)
- [![Walk through demo](https://img.youtube.com/vi/xXSdGRBPFjg/0.jpg)](https://www.youtube.com/watch?v=xXSdGRBPFjg)


## LAST UMCOMMIT
`````
git reset --hard HEAD~1
git push origin -f
`````

## License
The Spring PetClinic sample application is released under version 2.0 of the [Apache License](https://www.apache.org/licenses/LICENSE-2.0).
