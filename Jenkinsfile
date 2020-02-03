@Library('powerplant')
import org.powerplant.Singularity
import org.powerplant.EnvVars
import org.powerplant.Git
import org.powerplant.Hook
import org.powerplant.Email
import org.powerplant.File
import org.powerplant.Template
import org.powerplant.Bats

def singularity = new Singularity(this)
def envVars = new EnvVars(this)
def git = new Git(this)
def hook = new Hook(this)
def email = new Email(this)
def file = new File(this)
def template = new Template(this)
def bats = new Bats(this)

def imageFile = "/tmp/${SOFTWARE_NAME}.${SINGULARITY_RELEASE_VERSION}.simg"
def gitBranch = "master"

pipeline {
   agent any

    environment {
        SOFTWARE_NAME = "${params.SOFTWARE_NAME}"
        SINGULARITY_RELEASE_VERSION = "${params.SINGULARITY_RELEASE_VERSION}"
        SUBSTITUTED_VARS = "${params.SUBSTITUTED_VARS}"
        SINGULARITY_UPDATE_URL = "${params.SINGULARITY_UPDATE_URL}"
        SINGULARITY_DISPATCHED_BUILD_URL = "${params.SINGULARITY_DISPATCHED_BUILD_URL}"
        HTTP_MODE = "${params.HTTP_MODE}"
        Jenkins_Api_ID = "${params.Jenkins_Api_ID}"
        Jenkins_Api_Host = "${params.Jenkins_Api_Host}"
        Jenkins_Api_User = "${params.Jenkins_Api_User}"
        EMAIL_NOTIFICATION_LIST = "${params.EMAIL_NOTIFICATION_LIST}"
        TEMPLATE_VERSION = "${params.TEMPLATE_VERSION}"
        BUILD_CREDENTIAL_ID = "${params.BUILD_CREDENTIAL_ID}"
    }

    stages {
        stage('announce-version') {
            steps {
                sh 'echo "version: ${SINGULARITY_RELEASE_VERSION}"'
            }
        }

        stage('update-currrent-versions-list') {
            steps {
                script{
                    git.branch(gitBranch)
                    def currentVersionList = singularity.buildCurrentVersions(WORKSPACE, "Singularity.")
                    def jsonBody = singularity.setMutateSetPayload(SOFTWARE_NAME, currentVersionList)
                    def singularityResponse = singularity.apiCall(
                        SINGULARITY_UPDATE_URL, 
                        Jenkins_Api_ID, 
                        Jenkins_Api_HOST, 
                        Jenkins_Api_USER, 
                        SINGULARITY_API_KEY,
                        'PUT',
                        jsonBody
                    )
                    singularity.isValueInList(SINGULARITY_RELEASE_VERSION, 'current_versions', singularityResponse.getContent())
                }
            }
        } 

      stage('generate-recipe') {
            steps {
                script {
                    def buildStep = "template"
                    hook.createPreHookProperties(WORKSPACE, buildStep)
                    hook.callPreHook(WORKSPACE, buildStep)
                    envVars.loadEnvironmentVariables("${WORKSPACE}/pre_hook_${buildStep}.properties")
                    hook.viewPreHookProperties(WORKSPACE, buildStep)
                    template.templater("Singularity.template", "Singularity.${SINGULARITY_RELEASE_VERSION}")
                    sh 'cat ${WORKSPACE}/Singularity.${SINGULARITY_RELEASE_VERSION}'
                }
            }
      }

      stage('build-singularity-image') {
          steps {
              script {
                  singularity.buildImage(imageFile, "${WORKSPACE}/Singularity.${SINGULARITY_RELEASE_VERSION}", "--notest")
              }
          }
      }

      stage('test') {
            steps {
                script {
                    withEnv(["SINGULARITY_IMAGE_FILE=${imageFile}"]) {
                        envVars.filteredExport('!~ /\\./', "${WORKSPACE}/tests/env_file")
                        
                        if (! fileExists("${WORKSPACE}/tests/singularity_helper.bash") ) {
                            file.copy("${APP_DIR}/tests/singularity/singularity_helper.bash", "${WORKSPACE}/tests")
                            file.dos2unix("${WORKSPACE}/tests/singularity_helper.bash")
                        }
                         
                        sh "cat ${WORKSPACE}/tests/env_file"
                        bats.test("${WORKSPACE}/tests/tests.bats", "${WORKSPACE}/${SOFTWARE_NAME}.${SINGULARITY_RELEASE_VERSION}.tap")
                    }                        
                }
            }
      }

      stage('git-push') {
        steps{
                script {
                git.status()
                git.add("Singularity.${SINGULARITY_RELEASE_VERSION}")
                git.status()
                git.setIdentity('singularity_api', 'singularity_api@users.noreply.github.example.com')
                git.commit("Automated build of Singularity recipe ${SINGULARITY_RELEASE_VERSION}")
                git.setCredentials(BUILD_CREDENTIAL_ID)
                git.push(gitBranch, 10, 3)
            }
        }
      }

      stage('update-db-versions') {
         steps {
            script {
                def jsonBody = singularity.setMutateSetPayload(SOFTWARE_NAME, SINGULARITY_RELEASE_VERSION)
                singularity.apiCall(
                    SINGULARITY_UPDATE_URL, 
                    Jenkins_Api_ID, 
                    Jenkins_Api_HOST, 
                    Jenkins_Api_USER, 
                    SINGULARITY_API_KEY,
                    'PUT',
                    jsonBody
                )
            }
 
         }
      }
   }

    post {
        always {
            echo 'This will always run'

            script {
                if (fileExists("${SOFTWARE_NAME}.${SINGULARITY_RELEASE_VERSION}.xml")) {
                    archiveArtifacts artifacts: "${SOFTWARE_NAME}.${SINGULARITY_RELEASE_VERSION}.xml", fingerprint: true
                } 

                bats.publishResults("${SOFTWARE_NAME}.${SINGULARITY_RELEASE_VERSION}.tap")

                if (fileExists("Singularity.${SINGULARITY_RELEASE_VERSION}")) {
                    archiveArtifacts artifacts: "Singularity.${SINGULARITY_RELEASE_VERSION}", fingerprint: true
                } 

                if (fileExists(imageFile)) {
                    file.remove(imageFile)
                }
                
                email.sendResults(EMAIL_NOTIFICATION_LIST)
            }
             deleteDir() 
        }
        cleanup {
            script {
                def jsonBody = singularity.setMutateSetPayload(SOFTWARE_NAME, "${JOB_NAME} - ${SINGULARITY_RELEASE_VERSION}")
                singularity.apiCall(
                    SINGULARITY_DISPATCHED_BUILD_URL, 
                    Jenkins_Api_ID, 
                    Jenkins_Api_HOST, 
                    Jenkins_Api_USER, 
                    SINGULARITY_API_KEY,
                    'DELETE',
                    jsonBody
                )
            }
        }
    }
}